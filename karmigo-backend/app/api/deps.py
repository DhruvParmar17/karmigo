# app/api/deps.py
"""
Dependency helpers for authentication.

- Provides:
  * oauth2_scheme: OAuth2PasswordBearer -> used by OpenAPI/Swagger to show "Authorize".
  * security (HTTPBearer) + get_current_user -> runtime token verification and DB lookup.

Important:
- Avoid circular imports. If app.api.auth imports anything from this file,
  do NOT import oauth2_scheme back into app.api.auth — that creates import loops.
  If you need shared constants like SECRET_KEY/ALGORITHM, consider moving them to
  a small config module (e.g. app/core/config.py).
"""

from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials, OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from jose import jwt

from app.db.database import get_session
from app.db.models import User, Labour

# If your auth.py already defines SECRET_KEY and ALGORITHM and DOES NOT import deps,
# it's OK to import them here. If you find a circular import error, see the note above.
# Avoid circular imports by using config module
from app.core.config import SECRET_KEY, ALGORITHM

# OAuth2 scheme — used by Swagger UI to display the "Authorize" button.
# It points to your token endpoint (login). This does not itself validate tokens.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

# HTTP Bearer security (runtime verification). This expects header:
# Authorization: Bearer <token>
security = HTTPBearer()


async def get_current_user(
    creds: HTTPAuthorizationCredentials = Depends(security),
    session: AsyncSession = Depends(get_session),
) -> User:
    """
    Verifies the Bearer token, loads user from DB and returns a User model.
    Raises HTTPException(401) on failure.

    Usage example in a route:
        @router.get("/me")
        async def me(current_user: User = Depends(get_current_user)):
            return {"email": current_user.email}
    """
    token = creds.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("user_id")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token (no user_id)"
            )
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token expired")
    except jwt.JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    except Exception as e:
        print(f"Token validation error: {e}")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Could not validate credentials")

    # Load user from DB
    query = select(User).where(User.id == user_id)
    result = await session.execute(query)
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    return user


async def get_current_labour(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> Labour:
    """
    Dependency that ensures the authenticated user is also a Labour.
    Returns the Labour record.
    """
    query = select(Labour).where(Labour.email == current_user.email)
    result = await session.execute(query)
    labour = result.scalar_one_or_none()

    # AUTO-REGISTER IF MISSING (Lazy Registration)
    if not labour:
        try:
            print(f"DEBUG: Auto-creating labour for {current_user.email}")
            # Create a new labour profile for this user automatically
            labour = Labour(
                email=current_user.email,
                full_name=current_user.full_name or "Labour",
                phone=current_user.phone,
                wallet_balance=0.0
            )
            session.add(labour)
            await session.commit()
            await session.refresh(labour)
            print(f"DEBUG: Created labour {labour.id}")
        except Exception as e:
            print(f"ERROR creating labour: {e}")
            with open("error_log.txt", "a") as f:
                f.write(f"ERROR creating labour: {str(e)}\n")
                import traceback
                traceback.print_exc(file=f)
            
            raise HTTPException(status_code=500, detail=f"Failed to register labour profile: {str(e)}")
    
    # Verification Override for Demo Account
    is_demo_account = (
        (labour.email in ["dhurvparmar8@gmail.com", "dhruvparmar8@gmail.com"]) or 
        (labour.phone and (labour.phone == "9892593525" or labour.phone.endswith("9892593525"))) or
        (current_user.email in ["dhurvparmar8@gmail.com", "dhruvparmar8@gmail.com"]) or
        (current_user.phone and (current_user.phone == "9892593525" or current_user.phone.endswith("9892593525")))
    )
    if is_demo_account:
        labour.is_verified = True
        labour.verification_status = "verified"
    
    return labour


async def get_current_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    """
    Dependency to ensure the user is an Admin (is_superuser=True).
    """
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Admin privileges required"
        )
    return current_user

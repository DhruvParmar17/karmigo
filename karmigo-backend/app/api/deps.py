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
try:
    # prefer importing from app.api.auth (your current layout) so values match
    from app.api.auth import SECRET_KEY, ALGORITHM
except Exception:
    # fallback defaults (only used if import fails). Replace with secure values in production.
    SECRET_KEY = "karmigo-secret-key-change-this"
    ALGORITHM = "HS256"

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
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    except Exception:
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
        # Create a new labour profile for this user automatically
        labour = Labour(
            email=current_user.email,
            full_name=current_user.full_name or "Labour",
            phone=current_user.phone
        )
        session.add(labour)
        await session.commit()
        await session.refresh(labour)
    
    return labour

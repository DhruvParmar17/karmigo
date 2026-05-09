
try:
    with open("final_verify.log", "rb") as f:
        f.seek(0, 2)
        size = f.tell()
        f.seek(max(0, size - 2000))
        content = f.read()
        try:
             print(content.decode("utf-16le"))
        except:
             print(content.decode("utf-8", errors="ignore"))
except Exception as e:
    print(e)

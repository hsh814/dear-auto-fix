import os

def walk(path):
  for root, dirs, files in os.walk(path):
    for file in files:
      if file.endswith(".sh") or file.endswith(".py"):
        print(os.path.join(root, file))
        os.system("chmod +x " + os.path.join(root, file))

walk(".")
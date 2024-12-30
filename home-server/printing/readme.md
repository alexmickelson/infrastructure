


## what I am running on office server

```bash
sudo apt install python3-pip cups python3-cups hplip
pip install pycups fastapi "uvicorn[standard]" python-multipart
sudo hp-setup -i # manually configure printer...
python -m uvicorn print_api:app --reload --host 0.0.0.0
```

url: http://100.103.75.97:8000/
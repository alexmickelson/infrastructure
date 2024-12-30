import os
from pprint import pprint
import tempfile
from fastapi import FastAPI, File, UploadFile, Request
import cups
from fastapi.responses import HTMLResponse

app = FastAPI()


# @app.post("/print/")
# async def print_document(file: UploadFile = File(...)):
#     temp_file = tempfile.NamedTemporaryFile(delete=False)
#     temp_file.write(await file.read())
#     temp_file.close()
    
#     conn = cups.Connection(host="server.alexmickelson.guru")
    
#     printers = conn.getPrinters()
#     print(file.filename)
#     print(temp_file.name)
#     pprint(printers)
#     for printer in printers:
#         print(printer, printers[printer]["device-uri"])

#     default_printer = list(printers.keys())[0]


#     job_id = conn.printFile(default_printer, temp_file.name, f"FastAPI Print Job for {temp_file.name}", {})
#     os.unlink(temp_file.name)

#     return {"job_id": job_id, "file_name": file.filename}


@app.post("/print/")
async def print_document(file: UploadFile = File(...)):
    # Save the uploaded file to a temporary file
    temp_file = tempfile.NamedTemporaryFile(delete=False)
    temp_file.write(await file.read())
    temp_file.close()

    # Connect to the CUPS server on the host (use default CUPS connection)
    conn = cups.Connection()  # This will connect to localhost CUPS

    # Get the list of available printers
    printers = conn.getPrinters()
    print(file.filename)
    print(temp_file.name)
    pprint(printers)
    for printer in printers:
        print(printer, printers[printer]["device-uri"])

    # Use the default printer (first one in the list)
    default_printer = list(printers.keys())[0]

    # Print the file
    job_id = conn.printFile(default_printer, temp_file.name, f"FastAPI Print Job for {temp_file.name}", {})
    
    # Clean up the temporary file
    os.unlink(temp_file.name)

    return {"job_id": job_id, "file_name": file.filename}

@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    with open('src/index.html', 'r') as f:
        html_content = f.read()
        return HTMLResponse(content=html_content, status_code=200)
        

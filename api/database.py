import os
import pyodbc
from dotenv import load_dotenv

load_dotenv()


def get_connection():
    connection_string = os.getenv("SQLSERVER_CONNECTION_STRING")

    if not connection_string:
        raise RuntimeError("SQLSERVER_CONNECTION_STRING is missing from .env file.")

    return pyodbc.connect(connection_string)
# -*- coding: utf-8 -*-

import os
import pymysql

def db_execute(query, *args):
    args = args if args else None
    with db().cursor() as cursor:
        cursor.execute(query, args)
    db().commit()


def db():
    config = {
            "host": os.environ.get("ISUCON5_DB_HOST") or "localhost",
            "port": int(os.environ.get("ISUCON5_DB_PORT") or 3306),
            "username": os.environ.get("ISUCON5_DB_USER") or "root",
            "password": os.environ.get("ISUCON5_DB_PASSWORD"),
            "database": os.environ.get("ISUCON5_DB_NAME") or "isucon5q",
    }
    conn = pymysql.connect(
        host=config["host"],
        port=config["port"],
        user=config["username"],
        password=config["password"],
        db=config["database"],
        charset="utf8mb4",
        autocommit=True,
        cursorclass=pymysql.cursors.DictCursor)
    return conn

with db().cursor() as cursor:
    query = "select one, another from relations"
    cursor.execute(query)
    for relation in cursor:
        db_execute("DELETE FROM relations where one = %s AND another = %s", relation["another"], relation["one"])

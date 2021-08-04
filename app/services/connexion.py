from sqlalchemy.orm import session
from models.models import *

import configparser

config = configparser.ConfigParser()
config.read('data.cfg')

def getUserBtLoginAndPwd(login, pwd):
    return session.query(Utilisateur).filter_by(mail = login, motdepass = pwd).first()

def createUser(newUser):
    if newUser != None:
        session.add(newUser)
        session.commit()

def nextId(table):
    sql = "SELECT `id_question` FROM `questions` where `question`='" + table + "';"
    with engine.connect() as con:
        rs = con.execute(sql)
        for row in rs:
            return row[0]

def getAllQcm():
    sql = "SELECT * FROM `qcm`;"
    with engine.connect() as con:
        rs = con.execute(sql)
        return rs
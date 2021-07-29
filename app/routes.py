from flask import render_template, redirect, url_for, request, Flask
from create_app import app
from services.connexion import *
import json

@app.route('/', methods = ['POST', 'GET'])
def home():
    if request.method == 'POST':
        login = request.form['login']
        pwd = request.form['password']

        if (login and pwd) != None:
            user = getUserBtLoginAndPwd(login, pwd)
            if user != None:
                page = "admin" if user.role != 0 else "qcm"
                return redirect(url_for(page, name = user.nom))
            else:
                return redirect(url_for("registration"))
    
    return render_template("home.html")      



@app.route('/registration', methods = ['POST', 'GET'])
def registration():
    
    if request.method == 'POST':
        nom = request.form['nom']
        prenom = request.form['prenom']
        email = request.form['email']
        pwd = request.form['password']
        
        if nom and prenom and email and pwd != None:
            user = Utilisateur(nom=nom, prenom=prenom, mail= email, motdepass=pwd)
            createUser(user)
            return redirect(url_for("home"))
        
    return render_template("registration.html")



@app.route('/admin/<name>', methods = ['POST', 'GET'])
def admin(name):
    
    if request.method == 'GET':
        return render_template("admin.html", name = name)
    elif request.method == 'POST':
        pass



@app.route('/qcm/<name>', methods = ['POST', 'GET'])
def qcm(name):
    
    if request.method == 'GET':
        return render_template("qcm.html", name = name)
    elif request.method == 'POST':
        pass
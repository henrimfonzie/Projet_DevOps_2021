from flask import render_template, redirect, url_for, request, Flask
from create_app import app
from services.connexion import *
import json
from flask import session as sess

@app.route('/', methods = ['POST', 'GET'])
def home():
    if request.method == 'POST':
        login = request.form['login']
        pwd = request.form['password']

        if (login and pwd) != None:
            user = getUserBtLoginAndPwd(login, pwd)
            if user != None:
                role = "admin" if user.role != 0 else "user"   
                sess['user'] = {'id': user.id_user, 'nom' : user.nom, 'prenom' : user.prenom, 'role' : role, 'mail' : user.mail, 'pwd' : user.motdepass}
                return render_template("navbar.html",user=sess['user']) 
            else:
                return redirect(url_for("registration"))
    else :
        if "user" in sess :
            return render_template("navbar.html",user=sess['user']) 
        return render_template("home.html")      


@app.route('/signout')
def signout():
    sess.clear()
    return redirect(url_for("home"))

@app.route('/registration', methods = ['POST', 'GET'])
def registration():
    
    if request.method == 'POST':
        nom = request.form['nom']
        prenom = request.form['prenom']
        email = request.form['email']
        pwd = request.form['password']
        role = request.form['role']        
        if nom and prenom and email and pwd and role != None:
            user = Utilisateur(nom=nom, prenom=prenom, mail= email, motdepass=pwd, role=role)
            createUser(user)
            return redirect(url_for("home"))
    
    if "user" in sess:
        user = sess['user']
        return render_template("registration.html", user = user)
    else:
        return render_template("registration.html", user = None)



@app.route('/admin', methods = ['POST', 'GET'])
def admin():
    
    if request.method == 'GET':
        
        if "user" in sess:
            user = sess['user']
            if user['role'] == 'admin' :
                return render_template("admin.html", name = user)
        return render_template("404.html")
    elif request.method == 'POST':
        pass



@app.route('/qcm', methods = ['POST', 'GET'])
def qcm():
    
    if request.method == 'GET':
        if "user" in sess:
            user = sess['user']
            return render_template("qcm.html", user = user)
    elif request.method == 'POST':
        pass


@app.route('/user')
def user():
    if "user_nom" in sess:
        return render_template("navbar.html")
    else:
        return "<h1>user not found</h1>"


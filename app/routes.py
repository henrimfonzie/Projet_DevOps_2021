from flask import render_template, redirect, url_for, request, Flask
from create_app import app
from services.connexion import *
import json
from flask import session as sess

@app.route('/', methods = ['POST', 'GET'])
def home():
    cleanqst()
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
    cleanqst()
    sess.clear()
    return redirect(url_for("home"))

@app.route('/registration', methods = ['POST', 'GET'])
def registration():
    cleanqst()
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

@app.route('/createquestion', methods = ['POST', 'GET'])
def createquestion():
    cleanqst()
    if "user" in sess:
        user = sess['user']
        if user['role'] == 'admin' :    
            if request.method == 'GET':
                return render_template("question/ajout.html", user = user)

            else :
                question = request.form['question']
                nb_propositions = request.form['nb_propositions']        
                if question and nb_propositions != None and  question and nb_propositions != "" :
                    with engine.connect() as con:
                        con.execute("INSERT INTO `questions` (`question`) VALUES ('" +  question + "');")
                    next_id = nextId(question)
                    sess['question'] = {'id': next_id, 'nb' : int(nb_propositions), 'question' : question}
                        
                        #return render_template("reponses/ajout.html", user = user, nb = int(nb_propositions))
                    return redirect(url_for("createreponse")) 
                return render_template("question/ajout.html", user = user)

    else : 
        return render_template("404.html")

@app.route('/createreponse', methods = ['POST', 'GET'])
def createreponse():
    if "user" in sess and "question" in sess :
        user = sess['user']
        question = sess['question']

        if user['role'] == 'admin' :    
            if request.method == 'GET':
                return render_template("reponses/ajout.html", user = user, question = question)

            else :
                sql = ""
                data= {}
                for i in range(question["nb"]) :
                    x="question" + str(i)
                    try:
                        correct = request.form['rep']  
                        data[i] = request.form[x] 
                        if  data[i] :
                            if i !=  question["nb"]-1 :
                                if int(correct) == i :
                                    sql += "('"+str(question['id']) +"','" +data[i]+"',1),"
                                else :
                                    sql += "('"+str(question['id']) +"','" +data[i]+"',0),"
                            else :
                                if int(correct) == i :
                                    sql += "('"+str(question['id']) +"','" +data[i]+"',1)"
                                else :
                                    sql += "('"+str(question['id']) +"','" +data[i]+"',0)"
                        else :
                            return render_template("reponses/ajout.html", user = user, question = question)
                    except KeyError : 
                        return render_template("reponses/ajout.html", user = user, question = question)

                sess.pop('question')
                with engine.connect() as con:
                    rs = con.execute("INSERT INTO `reponses` (`id_qst`, `req`, `valeur`) VALUES " + sql + ";")        
                return redirect(url_for("home"))    
    else : 
        return render_template("404.html")

@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

@app.route('/GestionQCM', methods = ['GET'])
def GestionQCM():
    if "user" in sess :
        user = sess['user']
        if user['role'] == 'admin' :    
            if request.method == 'GET':
                qcm = getAllQcm()
                return render_template("qcm/consultation.html", user = user, qcm = qcm)
        return render_template("404.html")
    else : 
        return render_template("404.html")

@app.route('/qcmnewsub', methods = ['POST', 'GET'])
def qcmnewsub():
    if "user" in sess :
        user = sess['user']
        if user['role'] == 'admin' :    
            if request.method == 'POST':
                sujet = request.form['sujet']  
                if sujet!= None :
                    with engine.connect() as con:
                        con.execute("INSERT INTO `qcm` (`sujet`) VALUES ('" +  sujet + "');")
                    return redirect(url_for('GestionQCM'))
            return render_template("qcm/ajout.html", user = user)

@app.route('/qcmupdate/<id>', methods = ['GET'])
def qcmupdate(id):
    if "user" in sess :
        user = sess['user']
        if user['role'] == 'admin' :    
            if request.method == 'GET':
                sqlleft = "SELECT * FROM projet_devops_2021.questions A \
                    LEFT JOIN projet_devops_2021.avoir B ON A.id_question = B.id_qst and B.id_qcm = "+id+"\
                    WHERE B.id_avoir IS NULL;"
                sqlinner = "SELECT A.* FROM projet_devops_2021.questions A \
                    inner JOIN projet_devops_2021.avoir B ON A.id_question = B.id_qst and B.id_qcm = "+id+";"
                with engine.connect() as con:
                    left = con.execute(sqlleft)
                    inner = con.execute(sqlinner)
                # qcm = getAllQcm()
                # return render_template("qcm/ajout.html", user = user, qcm = qcm)
                return render_template("qcm/modification.html", user = user, id = id, left= left, inner = inner)
    return render_template("404.html")

@app.route('/qcmdel/<id>', methods = ['GET'])
def qcmdel(id):
    if "user" in sess :
        user = sess['user']
        if user['role'] == 'admin' :    
            if request.method == 'GET':
                with engine.connect() as con:
                    con.execute("DELETE FROM `qcm` WHERE `id_qcm`=" + id + ";")
                    con.execute("DELETE FROM `avoir` WHERE `id_qcm`=" + id + ";")
                return redirect(url_for('GestionQCM'))

@app.route('/qcmaddqst/<id>/<idqst>', methods = ['GET'])
def qcmaddqst(id,idqst):
    if "user" in sess :
        user = sess['user']
        if user['role'] == 'admin' :    
            if request.method == 'GET':
                with engine.connect() as con:
                    con.execute("insert into `avoir` (`id_qcm`,`id_qst`) VALUES (" + id + "," + idqst + ");")
                return redirect(url_for('qcmupdate', id = id))

@app.route('/qcmdelqst/<id>/<idqst>', methods = ['GET'])
def qcmdelqst(id,idqst):
    if "user" in sess :
        user = sess['user']
        if user['role'] == 'admin' :    
            if request.method == 'GET':
                with engine.connect() as con:
                    con.execute("DELETE FROM `avoir` where `id_qcm`=" + id + " and `id_qst`=" + idqst + ";")
                return redirect(url_for('qcmupdate', id = id))

def cleanqst():
    if "question" in sess :
        # delQuestion(sess['question']['question'])
        sql = "DELETE FROM `questions` WHERE `question`='" + sess['question']['question'] + "';"
        with engine.connect() as con:
            con.execute(sql)
        sess.pop('question')
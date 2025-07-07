from flask import Flask, request, jsonify, render_template
import string

app = Flask(__name__)


# Home route to serve the form
@app.route('/')
def home():
    return render_template('index.html')

# Password strength checking logic
def check_strength(password):
    score = 0
    if len(password) >= 8:
        score += 1
    if any(c.islower() for c in password):
        score += 1
    if any(c.isupper() for c in password):
        score += 1
    if any(c.isdigit() for c in password):
        score += 1
    if any(c in string.punctuation for c in password):
        score += 1

    if score <= 2:
        return "Weak"
    elif score == 3 or score == 4:
        return "Medium"
    else:
        return "Strong"

# API route
@app.route('/check-password', methods=['POST'])
def check_password():
    data = request.get_json()
    if not data or "password" not in data:
        return jsonify({"error": "Please provide a password."}), 400

    password = data["password"]
    strength = check_strength(password)

    return jsonify({
        "password": password,
        "strength": strength
    })

if __name__ == '__main__':
    app.run(debug=True)

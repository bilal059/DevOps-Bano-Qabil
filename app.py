from flask import Flask, request, jsonify, render_template_string
import string

app = Flask(__name__)

# HTML Template (inline instead of using separate index.html)
html_page = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Password Strength Checker</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f0f2f5;
      padding: 40px;
      text-align: center;
    }
    input, button {
      padding: 10px;
      margin: 10px;
      font-size: 16px;
    }
    .result {
      margin-top: 20px;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <h2>Password Strength Checker</h2>
  <input type="text" id="password" placeholder="Enter password">
  <button onclick="checkPassword()">Check Strength</button>
  <div class="result" id="result"></div>

  <script>
    function checkPassword() {
      const password = document.getElementById("password").value;

      fetch("/check-password", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ password: password })
      })
      .then(response => response.json())
      .then(data => {
        if (data.strength) {
          document.getElementById("result").innerText = `Strength: ${data.strength}`;
        } else {
          document.getElementById("result").innerText = `Error: ${data.error}`;
        }
      })
      .catch(error => {
        document.getElementById("result").innerText = "Something went wrong!";
      });
    }
  </script>
</body>
</html>
'''

# Home route to serve the form
@app.route('/')
def home():
    return render_template_string(html_page)

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

function loginAdmin() {
    var email = document.getElementById("email").value;
    var password = document.getElementById("password").value;

    firebase.auth().signInWithEmailAndPassword(email, password)
    .then((userCredential) => {
        var user = userCredential.user;
        window.location.href = "homeAdmin.html";
    })
    .catch((error) => {
        document.getElementById("error-message").innerText = error.message;
    });
}

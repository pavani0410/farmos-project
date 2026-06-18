# Leaf Detection Setup

The Hugging Face API key must not be committed to git.

Set one of these environment variables before starting the Spring Boot backend:

```powershell
$env:HUGGINGFACE_API_KEY = "<your-hugging-face-token>"
```

or:

```powershell
$env:HF_TOKEN = "<your-hugging-face-token>"
```

Then run the backend from `farmos`:

```powershell
.\mvnw.cmd spring-boot:run
```

The Flutter app calls:

```text
POST http://localhost:8081/api/leaf/detect
```

You can override the Hugging Face model without changing code:

```powershell
$env:HUGGINGFACE_MODEL_URL = "https://router.huggingface.co/hf-inference/models/your/model"
```

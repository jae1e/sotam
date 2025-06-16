# Sotam (소아과탐색기, 2024)
Sotam was a mobile service to help novice parents in South Korea easily find trustworthy pediatric clinics (소아과 병원/의원) nearby. Though the service is now closed, it's being open-sourced to support others interested in community-driven healthcare tools and local discovery services.

<p align="center">
<img src="examples/Screenshot 1.png" width="22%" />
<img src="examples/Screenshot 2.png" width="22%" />
<img src="examples/Screenshot 3.png" width="22%" />
<img src="examples/Screenshot 4.png" width="22%" />
</p>

🔗 Service Introduction Website (Archived)
You can still browse the introduction website here:
👉 https://sites.google.com/serenstudio.net/sotam

## 🌱 Why Sotam?
After I decided to take a career break, I wanted to build something meaningful and light to help people around me as a personal project. Many new parents—especially those with infants or new to a neighborhood—struggle to find reliable pediatric clinics. Existing hospital-finder services were too general, not well suited for children's healthcare, and lacked meaningful reviews from fellow parents. In reality, many moms relied on word-of-mouth—but that breaks down when you're new in town.

Sotam aimed to bridge that gap by combining verified government data with community insights, presented in a user-friendly map and list format.

## 📱 What Sotam Did
- Displayed nearby pediatric clinics on an interactive Kakao Map.
- Allowed parents to:
    - <b>Browse and search</b> by name, landmark, or current location.
    - <b>View clinic details</b> like working hours, weekend/night availability (e.g., 달빛어린이병원).
    - <b>Read and write reviews</b>, using structured survey forms to make contributing easy.
- Combined official medical databases with real user feedback for more context-rich information.

## 🔧 My Contributions
- Fetched and maintained the South Korean government's public medical facility dataset.
- Parsed and filtered the data to extract pediatric-specific clinics and relevant metadata (e.g., doctor name, specialization).
- Developed a custom survey and review system to collect and display feedback from users.
- Built a responsive and intuitive interface to present information via:
    - <b>Map view</b> (Kakao Map API and webview)
    - <b>List view</b> (sortable/filterable)
    - <b>Detailed view</b> (clinic info, reviews, working hours)
- Implemented a location-aware search experience.

## 💻 Tech Stack
- <b>Backend</b>: Go, MongoDB, Docker
- <b>Frontend</b>: Flutter (supports both Android and iOS)
- <b>Map Integration</b>: Kakao Map API
- <b>Deployment</b>: Dockerized backend services

## 📂 Open Source Goals
Though Sotam is no longer running as a live service, this repository is open-sourced in hopes that:
- Others can build local, community-focused tools with better healthcare discoverability.
- Developers interested in Flutter + Go + MongoDB stack can learn from a complete mobile service example.

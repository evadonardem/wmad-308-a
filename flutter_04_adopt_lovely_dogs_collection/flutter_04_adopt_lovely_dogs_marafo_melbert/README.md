# wmad-308-a

## Requirements

### Screens
1. Homepage
    - Select a breed of dog
    - Should show a random dog instance onLoad and onSelect
2. Adopted Dog Page
    - Show the listing of dogs adopted
3. Give Away Adopted Dog
    - Show the listing of dogs to give away
4. About Page
    - Show information about me

### Widgets
1. Navigation Bar
2. List View

### Features
1. Adopt Button on Homepage
2. Show Another One

 

---

## **Refactored Project Structure**
Organization of the project into multiple files to maintain clarity and reusability.

```
/lib
 ├── main.dart
 ├── screens/
 │   ├── home_page.dart
 │   ├── adopted_dogs_page.dart
 │   ├── give_away_page.dart
 │   ├── about_page.dart
 ├── widgets/
 │   ├── navigation_bar.dart
 │   ├── dog_card.dart
 ├── models/
 │   ├── dog.dart
 ├── services/
 │   ├── dog_service.dart
 ├── providers/
 │   ├── adopted_dogs_provider.dart
```

---

## **File Responsibilities**

### **1. `main.dart`**
- Entry point of the app.
- Sets up the `MaterialApp` with navigation routes.

### **2. Screens**
- **`home_page.dart`**: Main page where users select a breed, see a random dog, and adopt dogs.
- **`adopted_dogs_page.dart`**: Displays adopted dogs.
- **`give_away_page.dart`**: Displays dogs available for giving away.
- **`about_page.dart`**: Displays information about you.

### **3. Widgets**
- **`navigation_bar.dart`**: Contains the app’s navigation bar.
- **`dog_card.dart`**: A reusable widget to display dog details.

### **4. Models**
- **`dog.dart`**: Defines the `Dog` model.

### **5. Services**
- **`dog_service.dart`**: Fetches dog breeds and images from the API.

### **6. Providers**
- **`adopted_dogs_provider.dart`**: Manages the state of adopted dogs.

---

## **Implementation Plan**

### **1. Homepage (`home_page.dart`)**
- Displays a **dropdown** to select a breed.
- Shows a random dog on load and on selection.
- Includes **“Show Another One”** button to fetch another random dog.
- Features an **"Adopt"** button to save the dog to the adopted list.

### **2. Adopted Dog Page (`adopted_dogs_page.dart`)**
- Displays a list of adopted dogs using `adopted_dogs_provider.dart`.

### **3. Give Away Page (`give_away_page.dart`)**
- Displays a list of dogs available for giving away.

### **4. About Page (`about_page.dart`)**
- Static content about you.

---

## **How Separation of Concerns is Achieved**
1. **Screens handle UI and user interactions.**
2. **Widgets make UI components reusable.**
3. **Services handle API requests (dog images & breeds).**
4. **Providers manage app state (e.g., adopted dogs).**
5. **Models define structured data for consistency.**

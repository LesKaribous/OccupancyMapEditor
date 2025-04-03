
/*
  Occupancy Map Editor - Eurobot 2025
  -----------------------------------
  Un éditeur graphique pour générer une carte d’occupation
  - Peinture de tuiles (occupé/libre)
  - Sauvegarde automatique (.map + .h)
  - Export manuel du .h
  - Réinitialisation
  - Interface graphique avec quadrillage et image de fond
*/

import javax.swing.JFileChooser;
import java.io.File;

// === PARAMÈTRES GÉNÉRAUX ===
int cellSize = 150; // en mm
int scale = 50;     // pixels par cellule
int cols = 3000 / cellSize;
int rows = 2000 / cellSize;
int[][] grid = new int[rows][cols];

// === AUTO-SAVE ===
int autoSaveInterval = 30; // secondes
int lastAutoSaveTime = 0;
String lastSaveMessage = "";
int lastSaveDisplayTime = 0;
int saveMessageDuration = 3000; // ms

// === AIDE VISUELLE ===
boolean showHelp = true;
String[] helpText = {
  "[S] Sauvegarder le fichier .h",
  "[R] Réinitialiser la carte",
  "[H] Afficher/masquer cette aide",
  "[Clic gauche] Peindre (occupé)",
  "[Clic droit] Effacer (libre)",
  "[Auto-save] toutes les " + autoSaveInterval + "s dans occupancy.map + .h"
};

// === RESSOURCES ===
PImage terrain;

// === INITIALISATION ===
void settings() {
  size(cols * scale, rows * scale);
}

void setup() {
  loadTerrain();
  loadExistingMap();
}

// === AFFICHAGE PRINCIPAL ===
void draw() {
  background(255);
  drawTerrain();
  drawGridOverlay();
  drawOccupancy();
  autoSaveIfNeeded();
  drawSaveNotification();
  if (showHelp) drawHelpOverlay();
}

// === INTERACTIONS SOURIS ===
void mousePressed() {
  int x = mouseX / scale;
  int y = mouseY / scale;
  if (x < cols && y < rows) {
    grid[y][x] = (mouseButton == LEFT) ? 1 : 0;
  }
}

// === INTERACTIONS CLAVIER ===
void keyPressed() {
  if (key == 's') {
    JFileChooser chooser = new JFileChooser();
    chooser.setDialogTitle("Enregistrer le fichier .h");
    chooser.setSelectedFile(new File("occupancy_map.h"));
    if (chooser.showSaveDialog(null) == JFileChooser.APPROVE_OPTION) {
      saveHeaderTo(chooser.getSelectedFile());
    }
  } else if (key == 'h') {
    showHelp = !showHelp;
  } else if (key == 'r') {
    clearGrid();
    showMessage("Carte réinitialisée");
  }
}

// === CHARGEMENT ===
void loadTerrain() {
  terrain = loadImage("terrain.png");
  if (terrain != null) {
    terrain.resize(width, height);
    println("Image chargée : " + terrain.width + "x" + terrain.height);
  } else {
    println("Image non trouvée !");
  }
}

void loadExistingMap() {
  try {
    String[] lines = loadStrings("occupancy.map");
    for (int y = 0; y < min(rows, lines.length); y++) {
      String[] values = split(lines[y], ",");
      for (int x = 0; x < min(cols, values.length); x++) {
        grid[y][x] = int(values[x]);
      }
    }
    println("Map chargée depuis occupancy.map");
  } catch (Exception e) {
    println("Aucune map à charger, on part de zéro.");
  }
}

// === AFFICHAGE ===
void drawTerrain() {
  if (terrain != null) image(terrain, 0, 0);
}

void drawGridOverlay() {
  stroke(50);
  strokeWeight(1);
  noFill();
  for (int y = 0; y <= rows; y++) line(0, y * scale, cols * scale, y * scale);
  for (int x = 0; x <= cols; x++) line(x * scale, 0, x * scale, rows * scale);
}

void drawOccupancy() {
  noStroke();
  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      if (grid[y][x] == 1) {
        fill(255, 0, 0, 128);
        rect(x * scale, y * scale, scale, scale);
      }
    }
  }
}

void drawHelpOverlay() {
  int boxHeight = helpText.length * 20 + 20;
  fill(0, 180);
  rect(0, 0, width, boxHeight);
  fill(255);
  textSize(14);
  textAlign(LEFT, TOP);
  for (int i = 0; i < helpText.length; i++) {
    text(helpText[i], 10, 10 + i * 20);
  }
}

void drawSaveNotification() {
  if (millis() - lastSaveDisplayTime < saveMessageDuration) {
    fill(0, 150);
    rect(10, 10, 220, 30, 8);
    fill(255);
    textSize(14);
    textAlign(LEFT, CENTER);
    text(lastSaveMessage, 20, 25);
  }
}

// === SAUVEGARDE ===
void autoSaveIfNeeded() {
  if (millis() - lastAutoSaveTime > autoSaveInterval * 1000) {
    saveMap();
    lastAutoSaveTime = millis();
  }
}

void saveMap() {
  File defaultFile = new File(sketchPath("occupancy.map"));
  saveMapTo(defaultFile);
}

void saveMapTo(File file) {
  PrintWriter output = createWriter(file.getAbsolutePath());
  for (int y = 0; y < rows; y++) {
    String line = "";
    for (int x = 0; x < cols; x++) {
      line += grid[y][x];
      if (x < cols - 1) line += ",";
    }
    output.println(line);
  }
  output.flush();
  output.close();

  // Sauvegarde du .h
  File headerFile = new File(file.getParent(), "occupancy_map.h");
  saveHeaderTo(headerFile);
}

void saveHeaderTo(File file) {
  PrintWriter output = createWriter(file.getAbsolutePath());
  output.println("// Auto-generated occupancy map");
  output.println("const uint8_t occupancy_map[" + rows + "][" + cols + "] = {");
  for (int y = 0; y < rows; y++) {
    String line = "  {";
    for (int x = 0; x < cols; x++) {
      line += grid[y][x];
      if (x < cols - 1) line += ", ";
    }
    line += "}";
    if (y < rows - 1) line += ",";
    output.println(line);
  }
  output.println("};");
  output.flush();
  output.close();
  showMessage(".h sauvegardé à " + getTimeString());
}

// === OUTILS ===
void clearGrid() {
  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      grid[y][x] = 0;
    }
  }
}

void showMessage(String msg) {
  lastSaveMessage = msg;
  lastSaveDisplayTime = millis();
  println(msg);
}

String getTimeString() {
  return nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
}

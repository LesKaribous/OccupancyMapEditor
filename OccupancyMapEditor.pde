import javax.swing.JFileChooser;
import java.io.File;

int cellSize = 150; // mm
int scale = 50;     // pixels par cellule
int cols = 3000 / cellSize;
int rows = 2000 / cellSize;
int[][] grid = new int[rows][cols];
int autoSaveInterval = 30; // en secondes
int lastAutoSaveTime = 0;  // en millis
String lastSaveMessage = "";
int lastSaveDisplayTime = 0; // millis()
int saveMessageDuration = 3000; // ms

PImage terrain;

void settings() {
  size(cols * scale, rows * scale);
}

void setup() {
  terrain = loadImage("terrain2025.png");
  if (terrain == null) {
    println("Image non trouvée !");
  } else {
    println("Image chargée : " + terrain.width + "x" + terrain.height);
    //terrain.resize(cols * scale, rows * scale); // adapte à la grille
    terrain.resize(width, height);
    println("Image size: " + terrain.width + " x " + terrain.height);
    println("Fenêtre: " + width + " x " + height);
  }

  noStroke();

  // Charger une carte existante si dispo
  String[] lines = null;
  try {
    lines = loadStrings("occupancy.map");
    for (int y = 0; y < min(rows, lines.length); y++) {
      String[] values = split(lines[y], ",");
      for (int x = 0; x < min(cols, values.length); x++) {
        grid[y][x] = int(values[x]);
      }
    }
    println("Map chargée depuis occupancy.map");
  }
  catch (Exception e) {
    println("Aucune map à charger, on part de zéro.");
  }
}

void draw() {
  background(255); // ou autre fond selon ton goût

  if (terrain != null) {
    image(terrain, 0, 0); // DESSINE L’IMAGE D’ABORD
  }

  // Quadrillage en gris clair
  stroke(50);
  strokeWeight(1);
  noFill();

  for (int y = 0; y <= rows; y++) {
    line(0, y * scale, cols * scale, y * scale);
  }
  for (int x = 0; x <= cols; x++) {
    line(x * scale, 0, x * scale, rows * scale);
  }


  // Puis la grille par-dessus
  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      if (grid[y][x] == 1) {
        fill(255, 0, 0, 128); // cellule noire avec transparence
        rect(x * scale, y * scale, scale, scale);
      }
    }
  }
  // Sauvegarde automatique
  if (millis() - lastAutoSaveTime > autoSaveInterval * 1000) {
    saveMap();
    lastAutoSaveTime = millis();
  }
  // Notification visuelle de sauvegarde
  if (millis() - lastSaveDisplayTime < saveMessageDuration) {
    fill(0, 150); // fond semi-transparent
    rect(10, 10, 220, 30, 8);
    fill(255);
    textSize(14);
    textAlign(LEFT, CENTER);
    text(lastSaveMessage, 20, 25);
  }
}


// Peinture
void mousePressed() {
  int x = mouseX / scale;
  int y = mouseY / scale;
  if (x < cols && y < rows) {
    if (mouseButton == LEFT) {
      grid[y][x] = 1; // occupe
    } else if (mouseButton == RIGHT) {
      grid[y][x] = 0; // libre
    }
  }
}

// Export C++ et .map
void keyPressed() {
  if (key == 's') {
    JFileChooser chooser = new JFileChooser();
    chooser.setDialogTitle("Enregistrer le fichier .h");
    chooser.setSelectedFile(new File("occupancy_map.h"));

    int result = chooser.showSaveDialog(null);
    if (result == JFileChooser.APPROVE_OPTION) {
      File selectedFile = chooser.getSelectedFile();
      saveHeaderTo(selectedFile);
    }
  }
}

void saveMap() {
  File defaultFile = new File(sketchPath("occupancy.map"));
  saveMapTo(defaultFile);
}


void saveMapTo(File file) {
  PrintWriter output;

  // Sauvegarde .map à l'emplacement choisi
  output = createWriter(file.getAbsolutePath());
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

  // Génère aussi un .h dans le même dossier
  File headerFile = new File(file.getParent(), "occupancy_map.h");
  output = createWriter(headerFile.getAbsolutePath());
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

  // Affichage
  String t = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
  lastSaveMessage = "Sauvegardé à " + t;
  lastSaveDisplayTime = millis();
  println("Fichier .map sauvegardé dans : " + file.getAbsolutePath());
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

  // Affichage + notification visuelle
  String t = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
  lastSaveMessage = ".h sauvegardé à " + t;
  lastSaveDisplayTime = millis();
  println("Fichier .h sauvegardé dans : " + file.getAbsolutePath());
}

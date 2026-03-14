import sys
import json
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QPushButton, QFileDialog, QTreeWidget, QTreeWidgetItem, QMessageBox
from PyQt5.QtCore import Qt

class JsonReader(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Local JSON File Reader")
        self.setGeometry(100, 100, 800, 600)
        
        layout = QVBoxLayout()
        
        self.btn = QPushButton("Open JSON File")
        self.btn.clicked.connect(self.open_file)
        layout.addWidget(self.btn)
        
        self.tree = QTreeWidget()
        self.tree.setHeaderLabel("JSON Structure")
        layout.addWidget(self.tree)
        
        self.setLayout(layout)
    
    def open_file(self):
        fname = QFileDialog.getOpenFileName(self, 'Open JSON file', '', "JSON files (*.json)")
        if fname[0]:
            try:
                with open(fname[0], 'r', encoding='utf-8') as f:
                    data = json.load(f)
                self.display_json(data)
            except json.JSONDecodeError as e:
                QMessageBox.critical(self, "Error", f"Invalid JSON file: {e}")
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Error loading file: {e}")
    
    def display_json(self, data, parent=None):
        if parent is None:
            self.tree.clear()
            parent = self.tree.invisibleRootItem()
        
        if isinstance(data, dict):
            for key, value in data.items():
                item = QTreeWidgetItem([f"{key}: {type(value).__name__}"])
                parent.addChild(item)
                self.display_json(value, item)
        elif isinstance(data, list):
            for i, value in enumerate(data):
                item = QTreeWidgetItem([f"[{i}]: {type(value).__name__}"])
                parent.addChild(item)
                self.display_json(value, item)
        else:
            item = QTreeWidgetItem([str(data)])
            parent.addChild(item)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = JsonReader()
    window.show()
    sys.exit(app.exec_())
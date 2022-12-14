#!/bin/bash
#
# Setup environment for working with the project
#
# Usage: ./env-setup.sh
#

# Colors for output
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Check if the script is being run from the correct directory
SCRIPT_PATH="$(
  cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit
  pwd -P
)"

# URLs for th YOLOv7 resources
DATASET_URL="https://nomeroff.net.ua/datasets/autoriaNumberplateDataset-2022-08-01.zip"
WEIGHTS_URL="https://github.com/WongKinYiu/yolov7/releases/download/v0.1/yolov7_training.pt"
WEIGHTSV5_URL="https://github.com/ultralytics/yolov5/releases/download/v6.2/yolov5s.pt"

LOG_FILE="log.txt"

YOLO_PATH="${SCRIPT_PATH}/yolov7"
YOLOV5_PATH="${SCRIPT_PATH}/yolov5"
YOLO_VER="yolov7"
YOLOV5_VER="yolov5x"

VENV_DIR="${SCRIPT_PATH}/.venv"

DATASET_NAME="autoriaNumberplateDataset-2022-08-01"
WEIGHTS_NAME=$(basename $WEIGHTS_URL)
WEIGHTSV5_NAME=$(basename $WEIGHTS_URL)

# Check if the script is being run from the correct directory
echo -e "${PURPLE}[INFO] ${NC}Jumping to ${SCRIPT_PATH} ..."
cd "$SCRIPT_PATH" || exit

echo -e "${PURPLE}[INFO] ${NC}Starting environment setup ..."

if [ -z "$(ls -A "$YOLO_PATH")" ]; then
  # Clone the YOLOv7 repo as a submodule
  echo -e "${PURPLE}[INFO] ${NC}YoloV7 isn't loaded, cloning ..."
  cd "${YOLO_PATH}" || exit
  git submodule init >>$LOG_FILE 2>&1
  git submodule update >>$LOG_FILE 2>&1
fi

cd "$SCRIPT_PATH" || exit

if [ -z "$(ls -A "$YOLOV5_PATH")" ]; then
  # Clone the YOLOv7 repo as a submodule
  echo -e "${PURPLE}[INFO] ${NC}YoloV5 isn't loaded, cloning ..."
  cd "${YOLOV5_PATH}" || exit
  git submodule init >>$LOG_FILE 2>&1
  git submodule update >>$LOG_FILE 2>&1
fi

echo -e "${PURPLE}[INFO] ${NC}Yolo is loaded 🚀"

# Install YOLO system dependencies
echo -e "${PURPLE}[INFO] ${NC}Installing YOLO system dependencies ..."
# shellcheck disable=SC2024
sudo apt install ffmpeg libsm6 libxext6 libgl1 -y >>$LOG_FILE 2>&1

# Install Tesseract system dependencies
echo -e "${PURPLE}[INFO] ${NC}Installing Tesseract system dependencies ..."
# shellcheck disable=SC2024
sudo apt install tesseract-ocr -y >>$LOG_FILE 2>&1


echo -e "${PURPLE}[INFO] ${NC}Applying patches ..."

# Change classes count in YOLOv7 config
cd "${YOLO_PATH}/cfg/training/" || exit
echo -e "${PURPLE}[INFO] ${NC}Patching YOLOv7 ..."
sed -e 's/nc: 80/nc: 1/' "${YOLO_VER}.yaml" >"${YOLO_VER}.yaml.tmp" && mv "${YOLO_VER}.yaml.tmp" "${YOLO_VER}.yaml"
cd "$SCRIPT_PATH" || exit

if [ -d "${SCRIPT_PATH}/yolov5" ]; then
  echo -e "${PURPLE}[INFO] ${NC}Patching YOLOv5 ..."
  cd "${YOLO_PATH}/cfg/models" || exit
  sed -e 's/nc: 80/nc: 1/' "${YOLOV5_VER}.yaml" >"${YOLOV5_VER}.yaml.tmp" && mv "${YOLOV5_VER}.yaml.tmp" "${YOLOV5_VER}.yaml"
fi

echo -e "${PURPLE}[INFO] ${NC}Applying completed!"
cd "$SCRIPT_PATH" || exit

# Source or create the virtual environment
if [[ "$VIRTUAL_ENV" == "" ]]; then
  echo -e "${PURPLE}[INFO] ${NC}Virtual environment isn't exists, try to create ..."
  python3 -m venv "$VENV_DIR"
  # shellcheck source=/dev/null
  source "${VENV_DIR}/bin/activate"
fi

echo -e "${PURPLE}[INFO] ${NC}Virtual environment is exists or was created!"

echo -e "${PURPLE}[INFO] ${NC}Upgrading pip ..."
python -m pip install --upgrade pip &>/dev/null

# Check if pip requirements of this project are installed
if ! python3 -c "import pkg_resources; pkg_resources.require(open('${SCRIPT_PATH}/requirements.txt',mode='r'))" &>/dev/null; then
  echo -e "${PURPLE}[INFO] ${NC}Installing my dependencies ..."
  python -m pip install -r requirements.txt >>$LOG_FILE 2>&1
fi

# Check if pip requirements for YOLOv7 of this project are installed
if ! python3 -c "import pkg_resources; pkg_resources.require(open('${YOLO_PATH}/requirements.txt',mode='r'))" &>/dev/null; then
  echo -e "${PURPLE}[INFO] ${NC}Installing YOLO dependencies ..."

  if ! python -m pip install -r "${YOLO_PATH}/requirements.txt" >>$LOG_FILE 2>&1; then
    echo -e "${PURPLE}[ERROR] ${NC} 😔 I was unable to install these dependencies.
Maybe you should check the system requirements, for example RAM size." >&2
    exit 1
  fi
fi

echo -e "${PURPLE}[INFO] ${NC}All dependencies was installed 🚀"

if ! [ -f "${DATASET_NAME}.zip" ] && ! [ -d "${DATASET_NAME}" ]; then

  echo -e "${PURPLE}[INFO] ${NC}Dataset isn't downloaded ..."

  if ! [ -x "$(command -v wget)" ]; then
    echo -e "${RED}[WARNING] ${NC}'wget' is not installed. Try to install ..."
    # shellcheck disable=SC2024
    sudo apt install wget >>$LOG_FILE 2>&1
  fi

  wget $DATASET_URL
fi

ls -ahl

echo -e "${PURPLE}[INFO] ${NC}Dataset zip is loaded!"

if ! [ -d "${DATASET_NAME}" ]; then

  if ! [ -x "$(command -v unzip)" ]; then
    echo -e "${RED}[WARNING] ${NC}'unzip' is not installed. Try to install ..." >&2
    # shellcheck disable=SC2024
    sudo apt install unzip >>$LOG_FILE 2>&1
  fi

  echo -e "${PURPLE}[INFO] ${NC}Unzipping archive ..."

  unzip "${DATASET_NAME}.zip" >>$LOG_FILE 2>&1
fi

echo -e "${PURPLE}[INFO] ${NC}Archive is unzipped!"

echo -e "${PURPLE}[INFO] ${NC}Removing zip file ..."
rm -f "${DATASET_NAME}.zip"

if ! [ -f "$WEIGHTS_NAME" ]; then

  echo -e "${PURPLE}[INFO] ${NC}Weights 7 isn't downloaded ..."

  wget $WEIGHTS_URL
fi

if ! [ -f "$WEIGHTSV5_NAME" ]; then

  echo -e "${PURPLE}[INFO] ${NC}Weights 5 isn't downloaded ..."

  wget $WEIGHTSV5_URL
fi

echo -e "${PURPLE}[INFO] ${NC}Weights '${WEIGHTS_NAME}' is loaded!"
echo -e "${PURPLE}[INFO] ${NC}Running DVC 💻"

echo -e "${PURPLE}[INFO] ${NC}That's all!
Now you can simply run:\n\n\t  'dvc init'\n\n\tAnd, next:\n\n\t  'dvc repro'"

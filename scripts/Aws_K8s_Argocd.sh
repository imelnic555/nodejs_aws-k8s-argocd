#!/bin/bash

# Define all necessary environment variables
AWS_REGION="us-west-2"  # Adjust as needed
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
ECR_REPO_NAME="nodejs-app"
DOCKER_IMAGE="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest"
# GITHUB_USERNAME="imelnic555"
GITHUB_TOKEN="${GHPTOKEN}"  # use your deployed GHPTOKEN secret  # expects GITHUB_TOKEN set in environment
GITHUB_TOKEN=${{ secrets.GHPTOKEN }}
GITHUB_REPO="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/react_nodejs_plawyright.git"
CLONE_DIR="nodejs-app"
DEFAULT_BRANCH="main"
BRANCH_NAME="${1:-feature/full_stack_express}"  # Use argument, else default to your branch


############################################
# Ensure AWS credentials are set
############################################
echo "🔍 Checking AWS credentials..."
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ ERROR: AWS credentials are missing or invalid."
    exit 1
fi

############################################
# Install ArgoCD CLI if not installed
############################################
if ! command -v argocd &> /dev/null; then
    echo "🔧 ArgoCD CLI not found. Installing..."
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x /usr/local/bin/argocd
fi

############################################
# Clone the Node.js Repository
############################################
echo "📥 Cloning the Node.js app repository..."
if [ -d "$CLONE_DIR" ]; then
    echo "✅ Repository already cloned. Pulling latest changes..."
    cd "$CLONE_DIR"
    git pull origin main
    cd ..
else
    git clone --branch "$BRANCH_NAME" "$GITHUB_REPO" "$CLONE_DIR"
fi

############################################
# Build and Push Docker Image
############################################

if [ ! -f "$CLONE_DIR/Dockerfile" ]; then
    echo "❌ ERROR: Dockerfile not found in the cloned repository."
    exit 1
fi

echo "🔑 Logging into AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "📦 Creating ECR repository if not exists..."
aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $AWS_REGION >/dev/null 2>&1 || \
aws ecr create-repository --repository-name $ECR_REPO_NAME --region $AWS_REGION

echo "⚙️ Building Docker image..."
docker build -t $ECR_REPO_NAME:latest "$CLONE_DIR"

echo "🏷️ Tagging Docker image with AWS ECR URL..."
docker tag $ECR_REPO_NAME:latest $DOCKER_IMAGE

echo "🚀 Pushing Docker image to AWS ECR..."
docker push $DOCKER_IMAGE

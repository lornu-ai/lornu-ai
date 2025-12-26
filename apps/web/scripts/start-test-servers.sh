#!/bin/bash
# Start both frontend and backend servers for E2E tests
# This script is used in CI to start both servers before running Playwright tests

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting test servers...${NC}"

# Start backend API server in background
echo -e "${YELLOW}Starting backend API on port 8080...${NC}"
cd "$(dirname "$0")/../.." || exit 1
uv run -- uvicorn packages.api.main:app --host 0.0.0.0 --port 8080 &
BACKEND_PID=$!

# Wait for backend to be ready
echo -e "${YELLOW}Waiting for backend API to be ready...${NC}"
for i in {1..30}; do
  if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}Backend API is ready!${NC}"
    break
  fi
  if [ $i -eq 30 ]; then
    echo -e "${YELLOW}Backend API failed to start within timeout${NC}"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
  fi
  sleep 1
done

# Start frontend dev server in background
echo -e "${YELLOW}Starting frontend dev server on port 5174...${NC}"
cd apps/web || exit 1
bun run dev &
FRONTEND_PID=$!

# Wait for frontend to be ready
echo -e "${YELLOW}Waiting for frontend to be ready...${NC}"
for i in {1..30}; do
  if curl -s http://localhost:5174 > /dev/null 2>&1; then
    echo -e "${GREEN}Frontend is ready!${NC}"
    break
  fi
  if [ $i -eq 30 ]; then
    echo -e "${YELLOW}Frontend failed to start within timeout${NC}"
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
    exit 1
  fi
  sleep 1
done

echo -e "${GREEN}Both servers are running!${NC}"
echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"

# Keep script running and handle cleanup on exit
trap "echo 'Stopping servers...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true; exit" INT TERM

# Wait for both processes
wait $BACKEND_PID $FRONTEND_PID


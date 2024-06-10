# Use the official Node.js image
FROM node:16-alpine

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the application code to the working directory
COPY /app/server.js .

# Expose port 3000
EXPOSE 3000

# Run the Node.js application
CMD [ "node", "server.js" ]
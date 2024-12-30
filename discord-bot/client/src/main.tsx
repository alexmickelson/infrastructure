import React from "react";
import ReactDOM from "react-dom/client";
import "bootstrap";
import "bootstrap/scss/bootstrap.scss";
import "bootstrap-icons/font/bootstrap-icons.css";
import { App } from "./App";
import { WebSocketProvider } from "./contexts/WebSocketContext";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <WebSocketProvider>
      <App />
    </WebSocketProvider>
  </React.StrictMode>
);

import { healthController } from "../controllers/healthController.js";

export default function handler(req, res) {
  return healthController(req, res);
}

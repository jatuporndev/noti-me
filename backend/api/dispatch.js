import { dispatchController } from "../controllers/dispatchController.js";

export default async function handler(req, res) {
  return dispatchController(req, res);
}

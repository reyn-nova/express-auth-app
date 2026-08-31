// Augments Express's Request type so `req.userId` is recognized project-wide.
export {};

declare global {
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt';
import { AppError } from '../utils/AppError';

const COOKIE_NAME = process.env.COOKIE_NAME || 'access_token';

export function requireAuth(req: Request, _res: Response, next: NextFunction) {
  try {
    let token: string | undefined = req.cookies?.[COOKIE_NAME];

    if (!token && req.headers.authorization?.startsWith('Bearer ')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      throw new AppError('You are not signed in. Please sign in to continue.', 401);
    }

    const payload = verifyToken(token);
    req.userId = payload.sub;
    next();
  } catch (err) {
    if (err instanceof AppError) return next(err);
    next(new AppError('Invalid or expired session. Please sign in again.', 401));
  }
}

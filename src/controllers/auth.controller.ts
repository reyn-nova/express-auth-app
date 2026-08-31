import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/auth.service';
import { SignUpDto, SignInDto } from '../dto/auth.dto';

const COOKIE_NAME = process.env.COOKIE_NAME || 'access_token';
const COOKIE_SECURE = process.env.COOKIE_SECURE === 'true';
const isProd = process.env.NODE_ENV === 'production';

function setAuthCookie(res: Response, token: string) {
  res.cookie(COOKIE_NAME, token, {
    httpOnly: true,
    secure: COOKIE_SECURE || isProd,
    sameSite: 'lax',
    maxAge: 24 * 60 * 60 * 1000, // 1 day, keep in sync with JWT_EXPIRES_IN
    path: '/',
  });
}

export class AuthController {
  static async signUp(req: Request, res: Response, next: NextFunction) {
    try {
      const dto = req.body as SignUpDto;
      const { user, token } = await AuthService.signUp(dto);
      setAuthCookie(res, token);
      return res.status(201).json({
        status: 'success',
        message: 'Account created successfully',
        data: { user, token },
      });
    } catch (err) {
      next(err);
    }
  }

  static async signIn(req: Request, res: Response, next: NextFunction) {
    try {
      const dto = req.body as SignInDto;
      const { user, token } = await AuthService.signIn(dto);
      setAuthCookie(res, token);
      return res.status(200).json({
        status: 'success',
        message: 'Signed in successfully',
        data: { user, token },
      });
    } catch (err) {
      next(err);
    }
  }

  static async signOut(_req: Request, res: Response, next: NextFunction) {
    try {
      res.clearCookie(COOKIE_NAME, { path: '/' });
      return res.status(200).json({
        status: 'success',
        message: 'Signed out successfully',
      });
    } catch (err) {
      next(err);
    }
  }

  static async me(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.userId as string;
      const user = await AuthService.getById(userId);
      return res.status(200).json({ status: 'success', data: { user } });
    } catch (err) {
      next(err);
    }
  }
}

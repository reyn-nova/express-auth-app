import { AppDataSource } from '../config/data-source';
import { User } from '../entities/User';
import { AppError } from '../utils/AppError';
import { signToken } from '../utils/jwt';
import { SignUpDto, SignInDto } from '../dto/auth.dto';

const userRepository = () => AppDataSource.getRepository(User);

export class AuthService {
  static async signUp(dto: SignUpDto): Promise<{ user: User; token: string }> {
    const existing = await userRepository().findOne({
      where: { email: dto.email.toLowerCase() },
    });

    if (existing) {
      throw new AppError('An account with this email already exists', 409);
    }

    const user = userRepository().create({
      name: dto.name.trim(),
      email: dto.email.toLowerCase().trim(),
      password: dto.password, // hashed automatically by @BeforeInsert hook
    });

    await userRepository().save(user);

    const token = signToken({ sub: user.id, email: user.email });
    return { user, token };
  }

  static async signIn(dto: SignInDto): Promise<{ user: User; token: string }> {
    const user = await userRepository().findOne({
      where: { email: dto.email.toLowerCase().trim() },
    });

    // Use a generic message so we don't leak whether the email exists.
    if (!user) {
      throw new AppError('Invalid email or password', 401);
    }

    const isMatch = await user.comparePassword(dto.password);
    if (!isMatch) {
      throw new AppError('Invalid email or password', 401);
    }

    const token = signToken({ sub: user.id, email: user.email });
    return { user, token };
  }

  static async getById(id: string): Promise<User> {
    const user = await userRepository().findOne({ where: { id } });
    if (!user) {
      throw new AppError('User not found', 404);
    }
    return user;
  }
}

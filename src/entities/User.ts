import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
  BeforeInsert,
  BeforeUpdate,
} from 'typeorm';
import bcrypt from 'bcryptjs';

@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 100 })
  name!: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 255, unique: true })
  email!: string;

  // Excluded from JSON responses via the toJSON() override below.
  @Column({ type: 'varchar', length: 255 })
  password!: string;

  @Column({ type: 'boolean', default: false })
  isEmailVerified!: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  // Only auto-hash on insert. If you need to change a password later, hash
  // it explicitly in the service layer (e.g. `user.password = await
  // hashPassword(newPassword)`) before saving, to avoid re-hashing an
  // already-hashed value on unrelated updates.
  @BeforeInsert()
  async hashPasswordOnInsert() {
    if (this.password) {
      const salt = await bcrypt.genSalt(12);
      this.password = await bcrypt.hash(this.password, salt);
    }
  }

  async comparePassword(candidate: string): Promise<boolean> {
    return bcrypt.compare(candidate, this.password);
  }

  toJSON() {
    const { password, ...rest } = this;
    return rest;
  }
}

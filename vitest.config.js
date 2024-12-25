// @ts-check
import { defineConfig, mergeConfig } from 'vitest/config';
import config from './vite.config';

export default mergeConfig(config, defineConfig({
  test: { include: ['tests/unit/*.{test,spec}.{js,ts}'] }
}));

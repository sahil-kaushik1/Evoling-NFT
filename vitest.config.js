/// <reference types="vitest" />

import { defineConfig } from "vitest/config";
import { vitestSetupFilePath, getClarinetVitestsArgv } from "@hirosystems/clarinet-sdk/vitest";

/*
  In this file, Vitest is configured so that it works seamlessly with Clarinet and the Simnet.

  The `setupFiles` will load the clarinet vitest environment, which will:
  - run `before` hooks to initialize the simnet and `after` hooks to collect costs and coverage reports.
  - load custom vitest matchers to work with Clarity values (such as `expect(...).toBeUint()`)

  The `getClarinetVitestsArgv()` will parse options passed to the command `vitest run --`
    - vitest run -- --manifest ./Clarinet.toml  # pass a custom path
    - vitest run -- --coverage --costs          # collect coverage and cost reports
*/

export default defineConfig({
  test: {
    environment: 'clarinet',
    setupFiles: [vitestSetupFilePath],
    pool: 'forks',
    poolOptions: {
      threads: { singleThread: true },
      forks: { singleFork: true },
    },
    environmentOptions: {
      clarinet: getClarinetVitestsArgv()
    },
  },
});

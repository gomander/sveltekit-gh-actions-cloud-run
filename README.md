# Deploying a SvelteKit app to Cloud Run with GitHub Actions

This is a work-in-progress step-by-step guide to deploying a SvelteKit app as a
Google Cloud Run service using GitHub Actions and Docker.  
Additionally included in this project for demonstration purposes are:

* Unit tests
* End-to-end tests
* Environment variables

For convenience, the app also uses TypeScript and a `.editorconfig` file.

## Scaffolding a SvelteKit project

Use the following command to create a basic SvelteKit app in the `my-app`
directory. You can skip the directory name at the end of the command to create
the app in the current directory.

```bash
npm create svelte@latest my-app
```

Alternatively, use any other way to scaffold a SvelteKit project, like my
personal favourite Skeleton UI, or use this repository as a starting point.

## Dependencies and package managers

Once you've created a project and installed dependencies with `npm i` (or
`pnpm i` or `yarn`), start a development server:

```bash
npm run dev
```

You can use whichever package manager you like. For this example I've stuck with
NPM since it is the most widely used.  
Using another package manager in the GitHub Action or in the Docker container is
pretty simple. To switch to PNPM for example, just replace the lines

```bash
npm i
# or
npm ci
# ...
npm run test / build
npm prune --production
```
with
```bash
npm i -g pnpm
pnpm i --frozen-lockfile
# ...
pnpm test / build
pnpm prune --prod
```

## Testing

First install Playwright's dependencies with
```bash
npx playwright install --with-deps
```

Run your tests locally with
```bash
npm run test

# or to run only unit tests
npm run test:unit
# integration tests
npm run test:integration
```

## GitHub repository setup

In the case that you've used this repository as a base, you must either replace
the environment variables in `.github/workflows/main.yml`, or add the secrets to
your GitHub repository secrets under Settings > Security > Secrets and variables >
Actions > Secrets.  
The `GCP_PROJECT_ID` secret can just be replaced with your GCP project ID
without any issues, as it is not sensitive.  
The `GCP_SERVICE_ACCOUNT_KEY` secret *must* be added to your repository.  
For environment variables, only public environment variables should be passed
into the Dockerfile as environment variable arguments, as anyone with project
Viewer permissions or greater will be able to see these values.

## GitHub workflow

The GitHub workflow can be found in `.github/workflows/main.yml`. It contains a
`test` job and a `build-and-deploy` job. The `test` job will run first and check
that all the end-to-end tests and unit tests succeed.  
Once they do, the `build-and-deploy` job starts. It authenticates with Google
and sends the project root to Google Cloud to build the Docker container.

## Dockerfile

The Dockerfile has a multi-stage build, where the first container gets the
entire source code of the project and builds the app. Then, the second container
copies only the built app from the first and sets the environment and start
command. This makes the container as small as possible.  
Each step in the Dockerfile is explained briefly in comments in the file.

## Google Cloud Platform / Firebase project setup

A few manual steps will be necessary for this pipeline to work, but once
they've been done once, they will never need to be touched again.

1. Create a service account with Editor permissions

This can be done at https://console.cloud.google.com under IAM & Admin > Service
accounts. You must then manage the service account's keys and create a new JSON
key. Copy the contents of the JSON file into your GitHub repository's
`GCP_SERVICE_ACCOUNT_KEY` secret.

2. Enable the Cloud Build API, Artifact Registry API, and Cloud Run API for your
GCP project

Go to APIs & Services and click on the "Enable APIs and services" button at the top,
or go to https://console.cloud.google.com/apis/library in your Google Cloud project,
and search for these APIs. Select them, and enable them. You may be prompted to
upgrade your plan to pay-as-you-go, but the free quotas are quite generous and you
can set alerts to go off if you go above them.

3. After the first successful deployment, manually allow unauthenticated
invocations

After the first successful deployment, you will likely get a 403 if you try to access
the URL of the deployed Cloud Run service. To fix this, go to your Cloud Run service
in the Cloud Console and go to the Security tab. Then switch the Authentication
setting from "Require authentication" to "Allow unauthenticated invocations".

## Next steps

Things that can be done to expand upon this pipeline:

* Use Firebase Hosting to point your domain to the Cloud Run service
* Add another GitHub workflow and add a service for a `dev` branch

# Deploying a SvelteKit app to Cloud Run with GitHub Actions

This is a work-in-progress step-by-step guide to deploying a SvelteKit app as a
Google Cloud Run service using GitHub Actions and Docker.  
This can all be done entirely for free, but each of these services have a
certain free quota, and you will be charged if you go above it. The free quota
should be more than enough for most hobbyists and individuals.  
Additionally included in this project for demonstration purposes are:

* Unit tests
* End-to-end tests
* Environment variables

For convenience, the app also uses TypeScript and a `.editorconfig` file.

## Scaffolding a SvelteKit project

Use the following command to create a basic SvelteKit app in the `my-app`
directory. You can skip the directory name at the end of the command to create
the app in the working directory.

```sh
npm create svelte@latest my-app
```

Alternatively, use any other way to scaffold a SvelteKit project, like my
personal favourite Skeleton UI, or use this repository as a starting point.

## Dependencies and package managers

Once you've created a project and installed dependencies with `npm install` (or
`pnpm install` or `yarn`), start a development server:

```sh
npm run dev
```

You can use whichever package manager you like. For this example I've stuck with
NPM since it is the most widely used, but to change which one you use just
delete `package-lock.json` and tweak `main.yml` and `Dockerfile`. To switch to
PNPM for example, replace these lines in `main.yml`:

```yml
run: npm ci
# ...
run: npm run test
# ...
run: npm run build
# ...
run: cp package*.json Dockerfile build
```

with:

```yml
run: npm i -g pnpm; pnpm i --frozen-lockfile
# ...
run: pnpm test
# ...
run: pnpm build
# ...
run: cp package.json pnpm-lock.yaml Dockerfile build
```

and this line in `Dockerfile`:

```dockerfile
RUN npm ci
```

with:

```dockerfile
RUN npm i -g pnpm && pnpm i --frozen-lockfile
```

## Testing

First install Playwright's dependencies:
```sh
npx playwright install --with-deps
```

Run your tests locally:
```sh
npm run test
# or to run only unit tests
npm run test:unit
# the same for integration tests
npm run test:integration
```

## GitHub repository setup

### Static environment variables for your SvelteKit app

In the case that you've used this repository as a base, you must either replace
the environment variables in `.github/workflows/main.yml`, or add the variables
to your GitHub repository secrets under "Settings" > "Security" > "Secrets and
variables" > "Actions" > "Variables".  
For server-only, secret environment variables, add them to your GitHub
repository secrets, under the "Secrets" tab in the same places as the variables
above.

### GitHub variables and secrets for Google Cloud Platform configuration

- `GCP_PROJECT_ID`: a variable containing your GCP project ID. This example uses
"sveltekit-gh-actions-cloud-run". GCP project IDs are globally unique, so if you
choose something less unique, you may get some numbers appended to yours.
- `GCP_SERVICE_ID`: a variable containing the ID of your Cloud Run service. This
can be anything you want. This example uses "app".
- `GCP_SERVICE_REGION`: a variable containing the GCP region in which your Cloud
Run service will be hosted. Select the region closest to you/your users. This
example uses "us-central1".
- `GCP_SERVICE_ACCOUNT_KEY`: a secret containing a JSON key for a service
account with editor permission in your GCP project. How to get this key is
explained below in the Google Cloud Platform project setup section.

The `GCP_PROJECT_ID`, `GCP_SERVICE_ID`, and `GCP_SERVICE_REGION` variables can
be replaced inline with your GCP project ID, your Cloud Run service ID, and
the service region without any issues, as they are not sensitive. Do note that
the service region cannot be changed once set.  
The `GCP_SERVICE_ACCOUNT_KEY` secret *must* be added to your repository secrets,
as it is extremely sensitive.

## GitHub workflow

The GitHub workflow can be found in `.github/workflows/main.yml`. It contains a
job called `test-build-deploy`. The job runs on pushes to the main branch. It
sets up the environment, runs the tests, builds the app, and deploys it to
Google Cloud Run. This workflow is pretty basic and has lots of room to be
improved and expanded upon.  
The second-to-last command is a complicated mess that just deletes old unused
versions of your app from Artifact Registry. This is done because Google will
begin to charge you if you store more than 5 gigabytes there, and there is no
easier way to delete unused images. You don't need to understand it, just make
sure that if you replace the repository variables inline, you do so here as
well.

## Dockerfile

The Dockerfile is super basic, as Vite does all the hard work getting the app
production-ready. All it does is set up a Debian image running a long-term
support Node.js version, install production dependencies, and run `index.js` in
the built app as the preconfigured "node" user.  
The "node" user does not have access to the file system, so if you need to save
files on the server (NOT recommended!), delete this line.

## Google Cloud Platform project setup

A few manual steps will be necessary for this pipeline to work, but once
they've been done once, they will never need to be touched again.  
When following a link in this section, make sure that you check that
your GCP project is selected at the top left of the screen.

1. Create a service account with Editor permissions

This can be done through the Google Cloud Console under "IAM & Admin" > "Service
accounts". Direct link here:
https://console.cloud.google.com/iam-admin/serviceaccounts. Click the "Create
service account" button at the top. Give it whatever name you want (I usually go
with "GitHub Actions Deployer"), and give it the "Editor" role found in the
"Basic" category. Back in the service accounts overview, click on the new
service account, go to the "Keys" tab, and create a new JSON key. Copy the
contents of the JSON file into a new GitHub repository secret called
`GCP_SERVICE_ACCOUNT_KEY`.

2. Enable the Cloud Build API, Artifact Registry API, and Cloud Run API for your
GCP project

Go to "APIs & Services" and click on the "Enable APIs and services" button at
the top, or go to https://console.cloud.google.com/apis/library and search for
these APIs. Select them, and enable them. You may be prompted to upgrade your
plan to pay-as-you-go, but the free quotas are quite generous and you can set
alerts to go off if you go above them.

3. After the first successful deployment, manually allow unauthenticated
invocations

After the first successful deployment, you may get a 403 response if you try to
access the service URL of the deployed Cloud Run service. To fix this, go to
your Cloud Run service in the Cloud Console and in the "Security" tab, switch
the "Authentication" setting from "Require authentication" to "Allow
unauthenticated invocations".

## Next steps

Things that can be done to expand upon this pipeline:

* Use Firebase Hosting to point your domain to the Cloud Run service
* Add another GitHub workflow and add a service for a development branch
* Add dynamic environment variables with dotenv

### Point a Firebase Hosting site to your Cloud Run service

If you want a nicer URL than the service URL created for your Cloud Run service
(like https://app-magdwkhvxi-uc.a.run.app for example), or if you even have your
own domain you want to use, then the easiest way is to set up Firebase Hosting.  
Firebase is included for free with your GCP project, but can't be found in the
Google Cloud Console. Go to https://console.firebase.google.com and go through
the steps to set up your GCP project with Firebase. Once Firebase is set up,
find the "Hosting" section in the "Build" dropdown, and create a site.  
With Firebase Hosting enabled in your project, and a site created, create these
two files in the root of your SvelteKit project.

`.firebaserc`

```json
{
  "projects": {
    "default": "your-firebase-project-id"
  }
}
```

`firebase.json`

```json
{
  "hosting": {
    "site": "your-firebase-site-name",
    "rewrites": [
      {
        "source": "**",
        "run": {
          "serviceId": "your-cloud-run-service-id",
          "region": "your-cloud-run-service-region"
        }
      }
    ]
  }
}
```

Make sure `serviceId` and `region` here match your Cloud Run service's chosen ID
and region. This repository uses "app" and "us-central1".

Install the Firebase CLI.

```sh
npm i -g firebase-tools
```

Then run this command to apply the rewrite. This will only need to be done once.

```sh
firebase deploy --only hosting:your-firebase-site-name --project your-firebase-project-id
```

## A note on Google Cloud service accounts

The GitHub Actions Deployer service account you created will have far more
permissions than it needs. Your Cloud Run service will also run as the default
compute service account, which will also have far more permissions than your
service needs. Ideally, you should go back to IAM after a few weeks and
several deployments, and fix this.  
Your GitHub Actions Deployer should have its unused permissions removed, and you
should create a new service account for your Cloud Run service to act as.
Read more about best practices for service accounts at
https://cloud.google.com/iam/docs/best-practices-service-accounts.

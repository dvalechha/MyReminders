# Git Workflow Instructions for Cursor Agent

Follow these steps precisely to automate the PR and merge process after completing a task. Assume `git` and the GitHub CLI (`gh`) are installed and authenticated.

0. **Identify Current Branch:** 
   - Determine the name of the current working branch (e.g., `git branch --show-current`). Store this for subsequent steps.

1. **Stage Changes:** 
   - Add all modified, deleted, and new files to the staging area.
   - *Command:* `git add .`

2. **Commit Changes:** 
   - Create a commit with a meaningful message. 
   - **Instruction:** Analyze the changes made in the session and generate a concise, descriptive message (e.g., `feat: implement user authentication` or `fix: resolve layout overflow on mobile`).
   - *Command:* `git commit -m "<generated_message>"`

3. **Push to Remote:** 
   - Push the local commit(s) to the origin repository on the current branch.
   - *Command:* `git push origin <current_branch_name>`

4. **Create Pull Request (PR):** 
   - Open a PR to merge the current branch into the `main` branch using the GitHub CLI.
   - **Instruction:** Use the commit message as the PR title. For the body, provide a brief bulleted list of the key changes.
   - *Command:* `gh pr create --base main --head <current_branch_name> --title "<commit_message>" --body "<brief_description>"`

5. **Merge Pull Request:** 
   - Merge the PR into the `main` branch immediately.
   - **Instruction:** Use the squash merge method to keep the main history clean unless otherwise specified.
   - *Command:* `gh pr merge --squash --delete-branch` (the `--delete-branch` flag cleans up the remote branch after merging).

6. **Switch to Main Branch:** 
   - Move the local environment back to the `main` branch.
   - *Command:* `git checkout main`

7. **Synchronize Local Main:** 
   - Pull the latest changes from the remote `main` branch to ensure your local `main` reflects the merge.
   - *Command:* `git pull origin main`
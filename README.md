# 1678 Pit Scout 2018

This is a guideline for handling and contributing to the 2018 season’s projects.


## Application Information

The 2018 FRC 1678 Pit-Scout app, ran on an iPhone 5s. A student visits all the pits in the competition and talks to the teams to gather information like number of wheels on the robot, pit organization etc. They also take and upload photos of the robot.


## Use Notes

To select the "selected image", view the images and then tap on the one you want to select. This will set the selected image url, and dismiss the image gallery so that you can continue adding data.

If you add 5 or more images for a given team, you run the risk of causing the image gallery to significantly lag, and possibly crash.


## Style Guide

Use standard Swift code conventions. See [here](https://github.com/raywenderlich/swift-style-guide#correctness) for more information.
	
	
## Commit Guide

You should also make sure that you are writing good commit messages! Here are a couple articles on this: [1](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html) [2](http://chris.beams.io/posts/git-commit/).

Particularly, you should make sure to write your commits in the imperative mood ("Add somefeature", not "Added somefeature") and capitalize the first word. If the change is complicated, use multiple lines to describe it.

Additionally, you should try to make your commits as small as possible (often referred to as making "atomic" commits). This helps other people understand what you are doing.


## Contributing

Here's how to get your code into the main project repository:


### If you've just joined the team:

1. Make an account on GitHub.
2. Ask the App Programming lead to add your account to the frc1678 repositories.


### If it's the first time you contributed to a repo:

1. Fork the repo
  	+ Login to github and navigate to the repo.
  	+ Click the "Fork" button in the upper right corner of the screen.
2. Clone the main repo.
 	+ `git clone https://github.com/frc1678/<repo_name>.git`, where `<repo_name>` is the project repository name (eg. scout-2017, server-2017).
3. Add your fork as a remote.
        + `git remote add <what_you_want_to_refer_to_it_as> https://github.com/<your_github_username>/<repo_name>`

### Anytime you want to make a change:

1. Create and checkout a new branch.
 	 * `git checkout -b <your-branch-name>`, where `<your-branch-name>` is a descriptive name for your branch. Use dashes in the branch name, not underscores.
2. Make whatever code changes you want/need/ to make. Be sure to test your changes!
3. Commit your work locally.
  	+ Try to make your commits as atomic (small) as possible. For example, moving functions around should be different from adding features, and changes to one subsystem should be in a different commit than changes to another subsystem.
 	 + Follow [these](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html) conventions for commit messages.
 	 + If your change is anything more than a few lines or small fixes, don't skip the extended description. If you are always using git commit with the -m option, stop doing that.
See this [stackoverflow question](https://stackoverflow.com/questions/9562304/github-commit-with-extended-message) for instructions on how to write an extended commit description.
4. Push to your forked repo.
 	 + `git push <your_remote> <your_branch_name>`.
5. Submit a pull request.
 	 1. Log into github.
 	 2. Go to the page for your forked repo.
 	 3. Select the branch that you just pushed from the "Branch" dropdown menu.
 	 4. Click "New Pull Request".
 	 5. Review the changes that you made.
 	 6. If you are happy with your changes, click "Create Pull Request".
6. Wait
 	 + People must review (and approve of) your changes before they are merged.
  	 + Specifically, ***2 experienced students*** contributing to that project have to approve it
 	 + If there are any concerns about your pull request, fix them. Depending on how severe the concerns are, the pull request may be merged without it, but everyone will be happier if you fix your code. To update your PR, just push to the branch on your forked repo.
  	+ Don't dismiss someone's review when you make changes - instead, ask them to re-review it.
7. Merge your changes into master
	  + If there are no conflicts, push the "Squash and merge" button, write a good commit message, and merge the changes.
 	 + If there are conflicts, fix them locally on your branch, push them, and then squash and merge.


## Helpful Tips

### Other remotes

You can add "remotes" to github that refer to other people's robot code repos. This allows you to, for example, take a look at someone else's code to look over it. You would be able to `git checkout <name_of_person>/juicy-commit` to see it. To add a remote, just do `git remote add <name_of_person> https://github.com/<username>/<repo_name>.git`. Once you've done this, you can use `git fetch <name_of_person>` to get updated code from other people's repos!


### iOS Programming Tips

Check out this [guide](https://docs.google.com/document/d/19I2pF2Krz-MLcP4INNbAA4HgbnG3rdTHmwM8_2428go/edit?usp=sharing) for some helpful tips and tricks about using Xcode and writing in Swift!

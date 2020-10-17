# Script to Install Openstack

# Git flow & Command
1. Create a new branch

```shell
git checkout -b <new-branch-name>
```

Example
```shell
git checkout -b Keystone-2
```

2. Create a update code on the branch
3. Git add, commit, and push

```shell
git add <directory to add>
git commit -m "<message>"
git push -u origin <new-branch-name>:<new-branch-name>
```

4. Create a pull request to master
5. Add a reviewe, and assigne
6. Wait for Review
7. Merge Pull Request
8. Later, we could execute in the server without done it from scratch

# Git setup
Using SSH to Clone Github
1. Check ~/.ssh folder is there any id_rsa & id_rsa.pub
```shell
cd ~/.ssh
```
2. If there is none of it, then you should generate ssh keys.
Note : You could add passphrase if you like!
```shell
ssh-keygen
```
3. Add the SSH Key to your github account
4. Clone a repo using
```shell
git clone git@github.com:SOCaaS/<repo-name>
```
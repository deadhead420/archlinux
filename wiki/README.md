##Wiki script

  - Hey'all folks, I'm here to bring the important news about the life-changing technology you all will meet here today.

Do you use Arch? Or maybe you use Debian? No? Fedora? I can't hear you over there!

Gentoo? Ubuntu? Okay, the point is - **it doesn't matter**. With every Linux distro you will definitely stumble upon a thing that is beyound all of your expectations about how complicated just using a Linux distro can be. You'll not be afraid, however. You'll just launch your favourite browser, type in the address bar te URL of your preferred search engine and describe the problem, being a seasoned search engine user you are...

Now I bet the first link would be Arch Wiki. So how do we make your problem solving faster and thus your Linux experience more flawless?

We direct you to Arch wiki instantly, not even needing a GUI! Our latest software package allows you to search ever-so-helpful Arch Wiki right from your console. You don't have to switch to GUI, you don't have to launch your text-mode browser yourself, nor do you need to type in the long and bothersome URL of it! 

Like, seriously, was it wiki.arch.org? Or arch.wikipedia.org? Or maybe org.wiki.arch? With our solution, aimed on both veteran and 'newbie' users, you don't need to know anymore!

For example, you. Yes, you. I know you want to see that new additions in SSH article. We all know how we should change our default OpenSSL settings and upgrade it to a new version since so-infamous LulzAnonSec group made a research on the library, finding out more than 30 critical bugs, 356 non-critical bugs, 560 features unknown before and a body of dead rat.

Hey, that guy's doing it right now. Look at him, he's launching a browser. A Webkit-based browser. It's gonna use 64% of its CPU just to render a Flash-based advertisement that unsurprisingly came from all the extensions he might not even know of.
That took him about 30 seconds. **36.5201**, to be exact. Now what'd we do, having the power of our command-line interface text-mode search framework under our fingertips?

    arch-wiki openssl
    
###Arch Wiki. It's that simple.

  -  For a quick and easy way to install arch-wiki-cli regardless of distro I've created a simple install script. Asuming you already have wget installed simply run the following command to install arch-wiki-cli
      this is a short link to installer.sh, as sudo user, or root:
      
	wget -O - https://goo.gl/gsAO4J | sh

  -  Useage: 
		arch-wiki "search args here"
  
  -  Options:   
		arch-wiki --help (displays help info)
		         
        arch-wiki --language "langhere" "search args here" (displays the wiki in "langhere")
               
        arch-wiki --update (grabs a new script from git repo)
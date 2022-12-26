docker start
docker images
REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE

//testing
docker run --rm busybox echo hello_world 
Hello World!

docker images

REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE
busybox                latest              59788edf1f3e        4 weeks ago         3.41MB

------------------------------------------------------------------------------------------------------

 lxc-create -t download -n u1 -- --dist ubuntu --release DISTRO-SHORT-CODENAME --arch amd64
 lxc-ls --fancy
 lxc-start --name u1 --daemon
 lxc-info --name u1
 lxc-stop --name u1
 
 




packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "arch" {
  type = string
  default = "aarch64"
}

variable "region" {
  type = string
  default = "us-west-2"
}
variable "release_version" {
  type    = string
  default = ""
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  version = var.release_version != "" ? var.release_version : local.timestamp
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "rustyrazorblade/images/easy-cass-lab-base-${var.arch}-${local.version}"
  instance_type = "c7gd.xlarge"
  region        = "${var.region}"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-arm64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 16
    volume_type = "gp3"
    delete_on_termination = true
  }
}

build {
  name    = "easy-cass-lab"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "shell" {
    inline = [
      # "sudo umount -l -f /mnt", # needed early on before we do anything with /mnt
      "sudo apt update",
      "sudo apt upgrade -y",
      "sudo apt update",
      "sudo apt install -y wget sysstat unzip ripgrep ant ant-optional tree zfsutils-linux", # bpftrace was removed b/c it breaks bcc tools, need to build latest from source
      "sudo wget https://github.com/mikefarah/yq/releases/download/v4.41.1/yq_linux_arm64 -O /usr/local/bin/yq",
      "sudo chmod +x /usr/local/bin/yq",
    ]
  }



  # install pyenv and python
  provisioner "shell" {
    script = "install/install_python.sh"
  }

  provisioner "shell" {
    script = "install/install_fio.sh"
  }

  # install async profiler
  provisioner "shell" {
    inline = [
      "sudo sysctl kernel.perf_event_paranoid=1",
      "sudo sysctl kernel.kptr_restrict=0",
      "wget https://github.com/async-profiler/async-profiler/releases/download/v3.0/async-profiler-3.0-linux-arm64.tar.gz",
      "tar zxvf async-profiler-3.0-linux-arm64.tar.gz",
      "sudo mv async-profiler-3.0-linux-arm64 /usr/local/async-profiler"
    ]
  }


  provisioner "shell" {
    script = "install/install_bcc.sh"
  }

  provisioner "shell" {
    inline = [
     # "sudo apt install openjdk-8-jdk openjdk-8-dbg openjdk-11-jdk openjdk-11-dbg openjdk-17-jdk openjdk-17-dbg -y",
     # "sudo update-java-alternatives -s /usr/lib/jvm/java-1.11.0-openjdk-arm64",
       "wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && echo 'deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main' | sudo tee /etc/apt/sources.list.d/corretto.list",
       "sudo apt update; sudo apt install openjdk-8-jdk openjdk-8-dbg openjdk-11-jdk openjdk-11-dbg openjdk-17-jdk openjdk-17-dbg java-11-amazon-corretto-jdk java-17-amazon-corretto-jdk -y",
       "sudo update-java-alternatives -s /usr/lib/jvm/java-11-amazon-corretto",
      
      "sudo sed -i '/hl jexec.*/d' /usr/lib/jvm/.java-1.8.0-openjdk-arm64.jinfo"
    ]
  }

  # install my extra nice tools, exa, bat, fd, ripgrep
  # wrapper for aprof to output results to a folder content shared by nginx
  # open to what port?

  # plop a file in with all the aliases I like
  provisioner "file" {
    source      = "aliases.sh"
    destination = "aliases.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo mv aliases.sh /etc/profile.d/aliases.sh"
    ]
  }



  provisioner "shell" {
    inline = [
      "wget https://training.ragozin.info/sjk.jar",
      "sudo mv sjk.jar /usr/local/lib",
      ""
    ]
  }
}



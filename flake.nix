{
  outputs = { self }: {
    templates.rust-binary = {
      path = "./rust/binary";
      description = "A simple Rust binary project.";
    };
    templates.rust-binary-nodevenv = {
      path = "./rust/no-devenv/binary";
      description = "A simple Rust binary project.";
    };

    templates.default = self.templates.rust-binary;
  };
}

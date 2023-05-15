{
  outputs = { self }: {
    templates.rust-binary = {
      path = ./rust/binary;
      description = "A simple Rust binary project.";
    };
    templates.rust-binary-nodevenv = {
      path = ./rust-nodevenv/binary;
      description = "A simple Rust binary project.";
    };

    templates.default = self.templates.rust-binary;
  };
}

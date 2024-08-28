const hyprland = await Service.import("hyprland");

const Workspaces = () => {
  const activeId = hyprland.active.workspace.bind("id");
  const workspaces = hyprland.bind("workspaces").as((ws) =>
    ws
      .filter(({ id }) => id > 0)
      .sort((a, b) => (a.id < b.id ? -1 : 1))
      .map(({ id }) => {
        return Widget.Button({
          on_clicked: () => hyprland.messageAsync(`dispatch workspace ${id}`),
          child: Widget.Label(`${id}`),
          class_name: activeId.as((i) => `${i === id ? "focused" : ""}`),
        });
      }),
  );

  return Widget.Box({
    class_name: "workspaces",
    children: workspaces,
  });
};

export default Workspaces;

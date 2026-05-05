// Shared primitives — buttons, toggles, chips, status bar, bottom nav
// (Icon comes from Icons.jsx, loaded earlier in index.html)

const PrimaryButton = ({ children, onClick, disabled, style = {} }) => (
  <button className="btn btn-primary" onClick={onClick} disabled={disabled} style={style}>{children}</button>
);
const OutlinedButton = ({ children, onClick, style = {} }) => (
  <button className="btn btn-outlined" onClick={onClick} style={style}>{children}</button>
);
const TextButton = ({ children, onClick, style = {} }) => (
  <button className="btn btn-text" onClick={onClick} style={style}>{children}</button>
);

const Switch = ({ on, onChange }) => (
  <div className={"switch" + (on ? " on" : "")} onClick={() => onChange(!on)} role="switch" aria-checked={on} />
);

const ToggleRow = ({ icon, color, title, sub, on, onChange }) => (
  <div className="toggle-row">
    <div className="icon-pill" style={{ background: color }}><Icon name={icon} filled /></div>
    <div className="text">
      <div className="text-title">{title}</div>
      <div className="text-sub">{sub}</div>
    </div>
    <Switch on={on} onChange={onChange} />
  </div>
);

const Chip = ({ icon, children, blue = false }) => (
  <span className={"chip" + (blue ? " chip-blue" : "")}>
    {icon && <Icon name={icon} />}
    {children}
  </span>
);

const ProgressBar = ({ value, thin = false }) => (
  <div className={"progress-bar" + (thin ? " thin" : "")}>
    <div className="fill" style={{ width: `${Math.max(0, Math.min(100, value))}%` }} />
  </div>
);

const StatusBar = () => (
  <div className="status-bar">
    <span>9:41</span>
    <div className="icons">
      <Icon name="signal_cellular_alt" filled />
      <Icon name="wifi" filled />
      <Icon name="battery_full" filled />
    </div>
  </div>
);

const BottomNav = ({ active, onChange }) => {
  const items = [
    { id: "home", icon: "home", label: "Home" },
    { id: "courses", icon: "menu_book", label: "Courses" },
    { id: "progress", icon: "trending_up", label: "Progress" },
  ];
  return (
    <nav className="bottom-nav">
      {items.map(it => (
        <button key={it.id} className={"nav-item" + (active === it.id ? " active" : "")} onClick={() => onChange(it.id)}>
          <Icon name={it.icon} filled={active === it.id} />
          <span className="label">{it.label}</span>
        </button>
      ))}
    </nav>
  );
};

const NoticePill = ({ children }) => (
  <span className="notice-pill"><Icon name="warning_amber" />{children}</span>
);

Object.assign(window, {
  PrimaryButton, OutlinedButton, TextButton,
  Switch, ToggleRow, Chip, ProgressBar,
  StatusBar, BottomNav, NoticePill,
});

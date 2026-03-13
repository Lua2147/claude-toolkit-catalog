# Components Reference

## Contents
- forwardRef primitive components
- Composition with children
- Modal / Dialog pattern
- Inline editing components
- Anti-patterns

---

## Primitive Components with forwardRef

All low-level UI components in `components/control/ui/` use `forwardRef` so parent components can access the underlying DOM element (focus management, measurements, etc.).

```tsx
// components/control/ui/button.tsx
interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', loading = false, disabled, className = '', children, ...props }, ref) => {
    const base = 'inline-flex items-center justify-center gap-2 font-medium rounded-lg transition-colors focus-visible:outline-none focus-visible:ring-2';
    const variants = {
      primary: 'bg-primary text-primary-foreground hover:bg-primary/90',
      secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
      ghost: 'hover:bg-accent hover:text-accent-foreground',
      danger: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
    };
    const sizes = { sm: 'h-8 px-3 text-xs', md: 'h-9 px-4 text-sm', lg: 'h-11 px-6 text-base' };

    return (
      <button
        ref={ref}
        disabled={disabled || loading}
        className={`${base} ${variants[variant]} ${sizes[size]} ${className}`}
        {...props}
      >
        {loading && <Loader2 className="w-4 h-4 animate-spin" />}
        {children}
      </button>
    );
  }
);
Button.displayName = 'Button';
```

**Always set `displayName`** — React DevTools shows "ForwardRef" without it, making debugging painful.

---

## Composition with Radix UI Dialog

Wrap Radix primitives in typed components. Don't spread Radix props directly into your codebase — you lose type safety and coupling.

```tsx
// components/control/ui/modal.tsx
interface ModalProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  description?: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  children: ReactNode;
}

const sizeClasses = {
  sm: 'max-w-sm', md: 'max-w-md', lg: 'max-w-lg', xl: 'max-w-2xl',
};

export function Modal({ open, onClose, title, size = 'md', children }: ModalProps) {
  return (
    <Dialog open={open} onOpenChange={(isOpen) => { if (!isOpen) onClose(); }}>
      <DialogContent className={`${sizeClasses[size]} max-h-[90vh] flex flex-col gap-0 p-0`}>
        {title && (
          <DialogHeader className="px-6 py-4 border-b border-border">
            <DialogTitle>{title}</DialogTitle>
          </DialogHeader>
        )}
        <div className="flex-1 overflow-y-auto flex flex-col">
          {children}
        </div>
      </DialogContent>
    </Dialog>
  );
}
```

---

## FormField Wrapper Component

Separates label/error/hint layout from the input itself. This pattern lets you wrap any input (text, select, custom) consistently.

```tsx
// components/control/ui/form-field.tsx
interface FormFieldProps {
  label?: string;
  required?: boolean;
  error?: string;
  hint?: string;
  children: ReactNode;
}

export function FormField({ label, required, error, hint, children }: FormFieldProps) {
  return (
    <div className="space-y-1">
      {label && (
        <Label className={required ? "after:content-['*'] after:ml-0.5 after:text-red-500" : ''}>
          {label}
        </Label>
      )}
      {children}
      {error && <p className="text-xs text-red-600">{error}</p>}
      {hint && !error && <p className="text-xs text-muted-foreground">{hint}</p>}
    </div>
  );
}
```

---

## Inline Edit Component

Controlled component pattern for click-to-edit cells in the CRM table views.

```tsx
// components/control/ui/inline-edit.tsx — simplified
export function InlineText({ value, onSave, placeholder, multiline = false }: InlineTextProps) {
  const [editing, setEditing] = useState(false);
  const [editValue, setEditValue] = useState(value);
  const [saving, setSaving] = useState(false);
  const inputRef = useRef<HTMLInputElement | HTMLTextAreaElement>(null);

  useEffect(() => {
    if (editing) inputRef.current?.focus();
  }, [editing]);

  // Reset local value when prop changes (e.g., optimistic update rolled back)
  useEffect(() => { setEditValue(value); }, [value]);

  const handleSave = async () => {
    if (editValue === value) { setEditing(false); return; }
    setSaving(true);
    try {
      await onSave(editValue);
      setEditing(false);
    } finally {
      setSaving(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !multiline) { e.preventDefault(); handleSave(); }
    if (e.key === 'Escape') { setEditValue(value); setEditing(false); }
  };

  if (editing) {
    return multiline
      ? <textarea ref={inputRef as RefObject<HTMLTextAreaElement>} value={editValue} onChange={(e) => setEditValue(e.target.value)} onBlur={handleSave} onKeyDown={handleKeyDown} />
      : <input ref={inputRef as RefObject<HTMLInputElement>} value={editValue} onChange={(e) => setEditValue(e.target.value)} onBlur={handleSave} onKeyDown={handleKeyDown} />;
  }

  return (
    <span onClick={() => setEditing(true)} className="cursor-text hover:bg-muted/50 rounded px-1">
      {value || <span className="text-muted-foreground">{placeholder}</span>}
      {saving && <Loader2 className="inline w-3 h-3 ml-1 animate-spin" />}
    </span>
  );
}
```

---

### WARNING: Inline Object/Array Props Break Memoization

**The Problem:**

```tsx
// BAD - new object reference every render, React.memo is useless
function Parent() {
  return <KPICard config={{ title: 'Revenue', color: 'blue' }} />;
}

const KPICard = React.memo(({ config }) => { /* ... */ });
// React.memo never skips re-renders because config is always a new reference
```

**Why This Breaks:**
1. `{ title: 'Revenue', color: 'blue' }` creates a new object on every render
2. `React.memo` does shallow equality — new reference = always re-render
3. Defeats the purpose of memoization entirely

**The Fix:**

```tsx
// GOOD - stable reference, React.memo works correctly
const CONFIG = { title: 'Revenue', color: 'blue' } as const;

function Parent() {
  return <KPICard config={CONFIG} />;
}
// Or use useMemo if it depends on props:
const config = useMemo(() => ({ title, color }), [title, color]);
```

---

### WARNING: Index as Key in Dynamic Lists

NEVER use array index as `key` for lists that can be reordered, filtered, or have items removed.

```tsx
// BAD - inserting at index 0 remounts ALL subsequent items
{deals.map((deal, index) => <DealRow key={index} deal={deal} />)}

// GOOD - stable identity, React reconciles correctly
{deals.map((deal) => <DealRow key={deal.id} deal={deal} />)}
```

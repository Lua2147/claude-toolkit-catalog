# Forms Reference

## Contents
- react-hook-form + Zod (modal/complex forms)
- Inline editing pattern (CRM table cells)
- FormField wrapper
- Validation patterns
- Anti-patterns

---

## react-hook-form + Zod

Use for modal forms, multi-field forms, and anything with validation.

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const DealSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  value: z.number({ invalid_type_error: 'Must be a number' }).positive('Must be positive'),
  stage: z.enum(['prospect', 'qualified', 'proposal', 'closed_won', 'closed_lost']),
  close_date: z.string().optional(),
});

type DealFormValues = z.infer<typeof DealSchema>;

export function CreateDealModal({ onClose, onCreated }: CreateDealModalProps) {
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<DealFormValues>({
    resolver: zodResolver(DealSchema),
    defaultValues: { stage: 'prospect' },
  });

  const onSubmit = async (values: DealFormValues) => {
    const supabase = createClient();
    const { data, error } = await supabase.from('deals').insert(values).select().single();
    if (error) throw error;
    onCreated(data);
    onClose();
  };

  return (
    <Modal open onClose={onClose} title="Create Deal">
      <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-4">
        <FormField label="Deal Name" required error={errors.name?.message}>
          <Input {...register('name')} placeholder="Acme Corp Series A" />
        </FormField>

        <FormField label="Value (USD)" error={errors.value?.message}>
          <Input type="number" {...register('value', { valueAsNumber: true })} />
        </FormField>

        <FormField label="Stage" error={errors.stage?.message}>
          <Select onValueChange={(v) => setValue('stage', v as DealFormValues['stage'])}>
            <SelectTrigger><SelectValue placeholder="Select stage" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="prospect">Prospect</SelectItem>
              <SelectItem value="qualified">Qualified</SelectItem>
            </SelectContent>
          </Select>
        </FormField>

        <div className="flex justify-end gap-2 pt-2">
          <Button variant="ghost" type="button" onClick={onClose}>Cancel</Button>
          <Button type="submit" loading={isSubmitting}>Create Deal</Button>
        </div>
      </form>
    </Modal>
  );
}
```

---

## Inline Editing (CRM Cell Pattern)

For click-to-edit cells in deal/contact tables. Does NOT use react-hook-form — too heavy for single-field edits.

```tsx
// Usage
<InlineText
  value={deal.name}
  onSave={async (newName) => {
    const { error } = await supabase.from('deals').update({ name: newName }).eq('id', deal.id);
    if (error) throw error;
    // Parent re-fetches or updates local state
    refresh();
  }}
  placeholder="Enter deal name"
/>
```

Key behaviors (from `components/control/ui/inline-edit.tsx`):
- Click to enter edit mode
- `Enter` saves (single-line), `Shift+Enter` adds newline (multiline)
- `Escape` cancels without saving
- `onBlur` saves (clicking away)
- Shows spinner while `onSave` is in-flight
- Resets to prop `value` if parent updates it (for rollback)

---

## FormField Wrapper

Always use `FormField` to wrap inputs — it handles label, error, and hint layout consistently.

```tsx
// components/control/ui/form-field.tsx
<FormField
  label="Close Date"
  hint="Expected deal close date"
  error={errors.close_date?.message}
>
  <Input type="date" {...register('close_date')} />
</FormField>
```

---

## Controlled Select with react-hook-form

Radix `Select` doesn't support `register()` — use `Controller` instead.

```tsx
import { Controller } from 'react-hook-form';

<Controller
  name="stage"
  control={control}
  render={({ field }) => (
    <Select value={field.value} onValueChange={field.onChange}>
      <SelectTrigger><SelectValue /></SelectTrigger>
      <SelectContent>
        <SelectItem value="prospect">Prospect</SelectItem>
        <SelectItem value="qualified">Qualified</SelectItem>
      </SelectContent>
    </Select>
  )}
/>
```

---

## Zod Schema Patterns

```tsx
// Optional field that must be a valid URL if provided
const schema = z.object({
  website: z.string().url('Must be a valid URL').optional().or(z.literal('')),
  // Phone: optional but validated format if present
  phone: z.string().regex(/^\+?[\d\s()-]{7,}$/, 'Invalid phone').optional().or(z.literal('')),
  // Positive number or null
  arr: z.number().positive().nullable().optional(),
});

// Transform on parse
const schema = z.object({
  value: z.string().transform((v) => parseFloat(v)), // form input is string, DB expects number
});
```

---

### WARNING: Uncontrolled Inputs Without react-hook-form

**The Problem:**

```tsx
// BAD - manual ref management, no validation, no error state
function BadForm() {
  const nameRef = useRef<HTMLInputElement>(null);
  const handleSubmit = () => {
    const name = nameRef.current?.value;
    if (!name) alert('Name required'); // no per-field errors
    // submit...
  };
  return <input ref={nameRef} />;
}
```

**Why This Breaks:**
1. Validation logic is duplicated everywhere
2. No per-field error display
3. No submission state management
4. Impossible to reset programmatically

**The Fix:** Use `useForm` from react-hook-form for any form with more than 1 field.

---

### WARNING: Forgetting `valueAsNumber` for Number Inputs

```tsx
// BAD - register returns string, Zod expects number, runtime error
<input type="number" {...register('value')} />

// GOOD - tells react-hook-form to coerce to number
<input type="number" {...register('value', { valueAsNumber: true })} />
// Or use z.coerce.number() in Zod schema
```

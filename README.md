# FMD Folio — NHDCL E‑Library (Supabase edition)

The whole app is `public/index.html`. Books, files and admin sign-in live in Supabase:

- Project: `ifuavdyeydmcrumuuzdx` (https://ifuavdyeydmcrumuuzdx.supabase.co)
- Table `public.books` (catalogue), table `public.admins` (admin emails)
- Storage bucket `books` (public; PDFs in `pdf/`, covers in `covers/`, 50 MB per file)
- Anyone can read. Only signed-in users whose email is in `public.admins` can add, edit or remove.

## 0. Set up the database (one time)
Supabase dashboard → your project → **SQL Editor → New query**. Open `setup.sql`,
copy everything, paste, and click **Run**. It should finish with "Success. No rows returned".
It creates the tables, the `books` storage bucket, the security rules and the first admin.

## 1. Create your admin login (one time)
Supabase dashboard → your project → **Authentication → Users → Add user → Create new user**
- Email: the admin email (already on the admin list: gyeltshensheyrub@gmail.com)
- Password: choose one
- Tick **Auto Confirm User** → Create user

Recommended: **Authentication → Sign In / Providers** → turn off **Allow new users to sign up**.

## 2. Add more admins (optional)
Supabase → **SQL Editor**, run (use lowercase):
```sql
insert into public.admins (email) values ('colleague@example.com');
```
Then create their login as in step 1. Remove an admin with
`delete from public.admins where email = 'colleague@example.com';`

## 3. Deploy on Vercel
Put `public/`, `vercel.json`, `setup.sql` and this README at the top level of a GitHub repo,
import it at vercel.com/new (Framework preset **Other**), Deploy. No environment variables needed.

## Using it
Open the site → **Admin** → sign in with email + password → **Add PDFs**, edit or remove books.
Readers just browse and read.

## Notes
- Free Supabase projects pause after about a week with no activity. If the site shows
  "Can't reach the library database", open the Supabase dashboard and click **Restore project**.
- The publishable key inside index.html is meant to be public; the database rules protect your data.

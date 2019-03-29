import os
import json
import subprocess
from pathlib import Path

from pydrive.auth import GoogleAuth
from pydrive.drive import GoogleDrive

# PyDrive patch
from pydrive.files import GoogleDriveFile
from pydrive.files import MediaIoBaseUpload

def DeleteFile(self):
    try:
        self.auth.service.files().delete(fileId=self['id']).execute()
    except errors.HttpError:
        print('An error occurred.')
GoogleDriveFile.Delete = DeleteFile

def _BuildMediaBody(self):
    """Build MediaIoBaseUpload to get prepared to upload content of the file.
    Sets mimeType as 'application/octet-stream' if not specified.
    :returns: MediaIoBaseUpload -- instance that will be used to upload content.
    """
    if self.get('mimeType') is None:
      self['mimeType'] = 'application/octet-stream'
    return MediaIoBaseUpload(self.content, self['mimeType'], resumable=True)

GoogleDriveFile._BuildMediaBody = _BuildMediaBody


def try_upload_gdrive(drive, file_path, parent_id):

    max_try = 5
    uploaded = False

    n = 1
    while not uploaded and n <= max_try:
        try:
            upload_gdrive(drive, n, file_path, parent_id)
        except Exception as e:
            print(e)
        else:
            uploaded = True
            print("Success")

        n += 1


def upload_gdrive(drive, n_try, file_path, parent_id):

    file_path = Path(file_path)

    print(f"Upload '{file_path}' to Google Drive ({n_try})")

    gfile = drive.CreateFile()
    gfile.SetContentFile(str(file_path))
    gfile['title'] = str(file_path.name)
    gfile['parents'] = [{"id": parent_id}]
    gfile.Upload()


def remove_old_backup(drive, parent_id, n):

    print(f"Only keep the {n} last backups. Others are deleted.")

    files = drive.ListFile({'q': f"'{parent_id}' in parents and trashed=false"}).GetList()
    files_list = list(sorted([file['title'] for file in files], reverse=True))

    files_to_trash = files_list[n:]

    for file in files:
        if file['title'] in files_to_trash:
            print("Delete '{}'".format(file['title']))
            file.Delete()


def get_login():
    auth_settings = credential_dir / "settings.yaml"
    credentials_file = credential_dir / "credentials.json"

    gauth = GoogleAuth(settings_file=auth_settings)

    if credentials_file.is_file():
        gauth.LoadCredentialsFile(str(credentials_file))

    gauth.CommandLineAuth()
    gauth.SaveCredentialsFile(credentials_file=str(credentials_file))
    drive = GoogleDrive(gauth)
    return drive


def _get_last_backup(backup_dir):

    backup_dir = Path(backup_dir)

    b = sorted(list(os.listdir(backup_dir)))
    b = list(filter(lambda x: (backup_dir / x).is_file(), b))

    if len(b) > 0:
        backup_name = Path(b[-1]).name
        backup_full_name = backup_dir / backup_name

        return backup_full_name
    else:
        return False


def _get_backup_dir(name):
    backup_dir = main_backup_dir / name
    backup_dir.mkdir(parents=False, exist_ok=True)
    return backup_dir


if __name__ == '__main__':

    main_backup_dir = Path("../backups").resolve()
    credential_dir = Path("../pydrive").resolve()

    drive = get_login()

    websites = json.load(open((credential_dir / "websites.json")))

    for name, drive_id in websites.items():

        backup_dir = _get_backup_dir(name)
        backup_full_name = _get_last_backup(backup_dir)

        if backup_full_name:

            print(f"Processing {name}")
            try_upload_gdrive(drive, backup_full_name, drive_id)

            # Remove backup older than 10 days locally
            cmd = f'find {backup_dir} -name "*_wordpress_backup.7z" -mtime +10 -type f -delete'
            subprocess.run(cmd.split(" "))

            # Keep 10 last backup remotely
            remove_old_backup(drive, drive_id, 10)

        else:
            print(f"No backup for {name}")

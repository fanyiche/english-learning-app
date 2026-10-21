import {copyFile} from 'node:fs/promises';
await copyFile(new URL('../public/careers.json',import.meta.url),new URL('../ios/LingoGarden/careers.json',import.meta.url));
console.log('已同步 iOS 课程内容。');

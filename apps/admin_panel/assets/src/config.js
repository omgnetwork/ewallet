import BORING_LOADING from '../public/images/boring_loading.gif';

export const FUN_LOADING_GIF = false;
export const LOADING_GIF_SRC = {
  DEFAULT: [
    BORING_LOADING,
  ],
  FUN: [
    // Removed third party gifs. Feel free to fun loading gifs can be added here.
  ],
};

export const LOADING_GIF = FUN_LOADING_GIF ? LOADING_GIF_SRC.FUN : LOADING_GIF_SRC.DEFAULT;

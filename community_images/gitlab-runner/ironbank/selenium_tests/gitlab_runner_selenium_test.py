"""The selenium test."""
# pylint: skip-file

# Generated by Selenium IDE
import json  # pylint: disable=import-error disable=unused-import
import time  # pylint: disable=import-error disable=unused-import
import pytest  # pylint: disable=import-error disable=unused-import
from selenium import webdriver  # pylint: disable=import-error
from selenium.webdriver.chrome.options import Options  # pylint: disable=import-error
from selenium.webdriver.common.by import By  # pylint: disable=import-error
from selenium.webdriver.common.action_chains import ActionChains  # pylint: disable=import-error disable=unused-import
from selenium.webdriver.support import expected_conditions  # pylint: disable=import-error disable=unused-import
from selenium.webdriver.support.wait import WebDriverWait  # pylint: disable=import-error disable=unused-import
from selenium.webdriver.common.keys import Keys  # pylint: disable=import-error disable=unused-import
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities  # pylint: disable=import-error disable=unused-import
from selenium.webdriver.support import expected_conditions as EC


class TestGrafanatest1():
    """The test word press class for testing grafana image."""

    def setup_method(self, method):  # pylint: disable=unused-argument
        """setup method."""
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument("disable-infobars")
        chrome_options.add_argument("--disable-extensions")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--no-sandbox")
        self.driver = webdriver.Chrome(
            options=chrome_options)  # pylint: disable=attribute-defined-outside-init
        self.driver.implicitly_wait(10)

    def teardown_method(self, method):  # pylint: disable=unused-argument
        """teardown method."""
        self.driver.quit()

    def test_login(self, params):
        root_user_password = params['server']

        self.driver.get(
                "http://localhost:{}/login".format(
                    params["port"]))  # pylint: disable=consider-using-f-string
        self.driver.set_window_size(1366, 732)

        # Login
        self.driver.find_element(By.ID, "user_login").send_keys("root")
        self.driver.find_element(By.ID, "user_password").send_keys(root_user_password)
        self.driver.find_element(By.XPATH, "//label[contains(.,\'Remember me\')]").click()
        self.driver.find_element(By.XPATH, "//span[contains(.,\'Sign in\')]").click()

        # Create Project
        self.driver.get(
                "http://localhost:{}/projects/new#blank_project".format(
                    params["port"]))  # pylint: disable=consider-using-f-string
        self.driver.find_element(By.ID, "js-project-name-description").click()
        self.driver.find_element(By.ID, "project_name").click()
        self.driver.find_element(By.ID, "project_name").send_keys("First Project")
        self.driver.find_element(By.XPATH, "//div[@id=\'dropdown-toggle-btn-35\']/button/span/span/span").click()
        self.driver.find_element(By.XPATH, "//li[2]/span/span").click()
        self.driver.find_element(By.CSS_SELECTOR, ".form-group:nth-child(3) .gl-form-radio:nth-child(3) > .custom-control-label").click()
        self.driver.find_element(By.XPATH, "//span[contains(.,\'Create project\')]").click()

        # Add ssh runner
        self.driver.get(
                "http://localhost:{}/admin/runners/new".format(
                    params["port"]))  # pylint: disable=consider-using-f-string
        self.driver.find_element(By.XPATH, "//div[2]/label").click()
        self.driver.find_element(By.XPATH, "//span[contains(.,\'Create runner\')]").click()
        time.sleep(2)

        # Relogin to access Admin level pages
        if self.driver.current_url.endswith("users/sign_in"):
            # Login
            self.driver.find_element(By.ID, "user_login").send_keys("root")
            self.driver.find_element(By.ID, "user_password").send_keys(root_user_password)
            self.driver.find_element(By.XPATH, "//label[contains(.,\'Remember me\')]").click()
            self.driver.find_element(By.XPATH, "//span[contains(.,\'Sign in\')]").click()

        time.sleep(30)
        print("URL  : ", self.driver.current_url)
        print(self.driver.page_source)
        print("Token: ", self.driver.find_element(By.XPATH, "//code").text)
        print("Token: ", self.driver.find_element(By.CSS_SELECTOR, "code:nth-child(3)").text)

        # Write runner registeration token to file `runner_registeration_token_1`
        f = open("runner_registeration_token_1", "w")
        f.write(self.driver.find_element(By.XPATH, "//code").text)
        f.close()
        time.sleep(10)

        self.driver.get(
                "http://localhost:{}/root/first-project/-/ci/editor?branch_name=main".format(
                    params["port"]))  # pylint: disable=consider-using-f-string
        self.driver.find_element(By.XPATH, "//span[contains(.,\'Configure pipeline\')]").click()
        self.driver.find_element(By.XPATH, "//span[contains(.,\'Commit changes\')]").click()

        # Open a job for some log fetching
        self.driver.get(
                "http://localhost:{}/root/first-project/-/jobs/1".format(
                    params["port"]))  # pylint: disable=consider-using-f-string 
        time.sleep(5)
